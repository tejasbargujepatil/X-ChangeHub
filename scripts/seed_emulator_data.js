const admin = require('../functions/node_modules/firebase-admin');

// SAFETY CHECK: Ensure emulators are configured
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || 'localhost:9099';

console.log('⚡ Initializing Firebase Admin for Local Emulator Suite...');
console.log(`- Firestore Emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
console.log(`- Auth Emulator: ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);

admin.initializeApp({
  projectId: 'xchangehub-f61be',
});

const auth = admin.auth();
const db = admin.firestore();

async function createOrUpdateUser(uid, email, password, displayName, customClaims = {}) {
  try {
    await auth.getUser(uid);
    console.log(`  Updating existing user ${email}...`);
    await auth.updateUser(uid, { email, password, displayName });
  } catch (e) {
    console.log(`  Creating new user ${email}...`);
    await auth.createUser({ uid, email, password, displayName });
  }

  if (Object.keys(customClaims).length > 0) {
    await auth.setCustomUserClaims(uid, customClaims);
    console.log(`  Set custom claims for ${email}:`, customClaims);
  }
}

async function seed() {
  console.log('\n==================================================');
  console.log('SEEDING XCHANGEHUB LOCAL DEMO DATA');
  console.log('==================================================\n');

  // 1. Create Accounts
  console.log('1. Creating Auth Accounts...');
  await createOrUpdateUser(
    'test-mentor-uid',
    'mentor@xchangehub.local',
    'Password123!',
    'Test Mentor'
  );

  await createOrUpdateUser(
    'test-learner-uid',
    'learner@xchangehub.local',
    'Password123!',
    'Test Learner'
  );

  await createOrUpdateUser(
    'test-reviewer-uid',
    'reviewer@xchangehub.local',
    'Password123!',
    'Test Reviewer',
    { reviewer: true }
  );

  // 2. User Profiles
  console.log('\n2. Populating User Profiles...');
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.collection('users').doc('test-mentor-uid').set({
    uid: 'test-mentor-uid',
    fullName: 'Test Mentor',
    username: 'testmentor',
    email: 'mentor@xchangehub.local',
    skillsToTeach: ['Python', 'Data Science'],
    skillsToLearn: ['Web Development'],
    verifiedSkills: ['Python'],
    xpPoints: 1500,
    level: 3,
    completedExchanges: 5,
    completedProjects: 2,
    badges: ['Top Mentor', 'Python Expert'],
    averageRating: 4.9,
    bio: 'Passionate Python developer & data enthusiast.',
    createdAt: now,
  });

  await db.collection('users').doc('test-learner-uid').set({
    uid: 'test-learner-uid',
    fullName: 'Test Learner',
    username: 'testlearner',
    email: 'learner@xchangehub.local',
    skillsToTeach: ['Flutter', 'Web Development'],
    skillsToLearn: ['Python', 'Data Science'],
    verifiedSkills: [],
    xpPoints: 350,
    level: 1,
    completedExchanges: 0,
    completedProjects: 0,
    badges: ['Eager Learner'],
    averageRating: 5.0,
    bio: 'Flutter developer expanding into Python.',
    createdAt: now,
  });

  await db.collection('users').doc('test-reviewer-uid').set({
    uid: 'test-reviewer-uid',
    fullName: 'Test Reviewer',
    username: 'testreviewer',
    email: 'reviewer@xchangehub.local',
    skillsToTeach: ['Quality Assurance'],
    skillsToLearn: [],
    verifiedSkills: [],
    xpPoints: 5000,
    level: 10,
    completedExchanges: 20,
    completedProjects: 10,
    badges: ['Reviewer'],
    role: 'reviewer',
    createdAt: now,
  });

  // 3. Mentor Quality Metrics
  console.log('\n3. Seeding Mentor Quality Metrics...');
  await db.collection('mentor_metrics').doc('test-mentor-uid').set({
    userId: 'test-mentor-uid',
    topicDeliveryRate: 85.0,
    learningPlansCompleted: 2,
    topicsLearnerConfirmed: 8,
    validatedLearningIssues: 0,
    qualityScore: 88,
    sufficientHistory: true,
    updatedAt: now,
  });

  // 4. Skill Exchange (Active)
  console.log('\n4. Creating Active Skill Exchange...');
  await db.collection('skill_exchanges').doc('demo-exchange-1').set({
    id: 'demo-exchange-1',
    requesterId: 'test-learner-uid',
    requesterName: 'Test Learner',
    teacherId: 'test-mentor-uid',
    teacherName: 'Test Mentor',
    skillRequested: 'Python',
    skillOffered: 'Flutter',
    status: 'accepted',
    message: 'Looking forward to learning Python fundamentals!',
    scheduledTime: new Date(Date.now() + 86400000).toISOString(),
    createdAt: now,
  });

  // 5. Active Learning Plan
  console.log('\n5. Creating Active Learning Plan...');
  await db.collection('learning_plans').doc('demo-exchange-1').set({
    id: 'demo-exchange-1',
    exchangeId: 'demo-exchange-1',
    mentorId: 'test-mentor-uid',
    learnerId: 'test-learner-uid',
    skillName: 'Python',
    status: 'active',
    createdAt: now,
    updatedAt: now,
    modules: [
      {
        id: 'mod-1',
        title: 'Python Fundamentals',
        description: 'Core basics of Python programming',
        orderIndex: 0,
        topics: [
          {
            id: 'topic-var-1',
            title: 'Variables & Assignment',
            expectedOutcome: 'Understand variables and assignment.',
            orderIndex: 0,
            mentorStatus: 'taught',
            learnerStatus: 'completed',
            mentorTaughtAt: new Date().toISOString(),
            learnerConfirmedAt: new Date().toISOString(),
          },
          {
            id: 'topic-types-2',
            title: 'Data Types & Operations',
            expectedOutcome: 'Understand common Python data types.',
            orderIndex: 1,
            mentorStatus: 'taught',
            learnerStatus: 'partiallyUnderstood',
            mentorTaughtAt: new Date().toISOString(),
          },
          {
            id: 'topic-func-3',
            title: 'Functions & Scope',
            expectedOutcome: 'Write and understand basic Python functions.',
            orderIndex: 2,
            mentorStatus: 'taught',
            learnerStatus: 'needHelp',
            mentorTaughtAt: new Date().toISOString(),
          },
        ],
      },
    ],
  });

  // 6. Learning Issue (Under Review)
  console.log('\n6. Seeding Learning Issue under review...');
  await db.collection('learning_issues').doc('demo-issue-1').set({
    id: 'demo-issue-1',
    planId: 'demo-exchange-1',
    exchangeId: 'demo-exchange-1',
    topicId: 'topic-func-3',
    reporterId: 'test-learner-uid',
    reportedId: 'test-mentor-uid',
    issueType: 'topicPoorlyUnderstood',
    status: 'underReview',
    notes: 'The explanation of function scope and return values was unclear during the session.',
    evidenceSnapshot: {
      topicTitle: 'Functions & Scope',
      reportedBy: 'Test Learner',
      reportedUser: 'Test Mentor',
      createdAt: new Date().toISOString(),
    },
    createdAt: now,
  });

  console.log('\n==================================================');
  console.log('✅ DEMO DATA SEEDED SUCCESSFULLY!');
  console.log('==================================================');
  console.log('\nTest Accounts Available:');
  console.log('- Learner:  learner@xchangehub.local  / Password123!');
  console.log('- Mentor:   mentor@xchangehub.local   / Password123!');
  console.log('- Reviewer: reviewer@xchangehub.local / Password123!\n');
}

seed().then(() => process.exit(0)).catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
