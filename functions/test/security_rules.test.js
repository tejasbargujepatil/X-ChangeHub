/**
 * Firestore Security Rules Assertion Test Suite for Phase 4 Security Hardening
 *
 * Requirements:
 * Uses @firebase/rules-unit-testing to verify server-side authorization enforcement
 * against Firestore Security Rules using simulated Firebase Auth Custom Claims.
 */

const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

let testEnv;

describe('Phase 4 Security Rules Hardening Suite', () => {
  beforeAll(async () => {
    const rulesPath = path.resolve(__dirname, '../../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: 'xchangehub-security-test',
      firestore: { rules },
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // TEST 1: Standard user cannot resolve an issue
  test('TEST 1: Standard user cannot resolve a Learning Issue', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const issueRef = stdDb.collection('learning_issues').doc('issue_001');

    await assertFails(
      issueRef.update({
        status: 'resolved',
        resolution: 'correctiveSession',
        resolvedBy: 'user_standard',
      })
    );
  });

  // TEST 2: Standard user cannot dismiss an issue
  test('TEST 2: Standard user cannot dismiss a Learning Issue', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const issueRef = stdDb.collection('learning_issues').doc('issue_001');

    await assertFails(
      issueRef.update({
        status: 'dismissed',
        resolution: 'dismissed',
        resolvedBy: 'user_standard',
      })
    );
  });

  // TEST 3: Standard user cannot modify reviewer fields
  test('TEST 3: Standard user cannot modify reviewer fields', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const issueRef = stdDb.collection('learning_issues').doc('issue_001');

    await assertFails(
      issueRef.update({
        resolutionNotes: 'Attempted self resolution by user',
      })
    );
  });

  // TEST 4: Standard user cannot create an intervention
  test('TEST 4: Standard user cannot create an intervention', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const intRef = stdDb.collection('learning_interventions').doc('int_001');

    await assertFails(
      intRef.set({
        interventionId: 'int_001',
        issueId: 'issue_001',
        targetUserId: 'target_001',
        assignedBy: 'user_standard',
        action: 'correctiveSession',
        status: 'pending',
      })
    );
  });

  // TEST 5: Standard user cannot modify an intervention
  test('TEST 5: Standard user cannot modify an intervention', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const intRef = stdDb.collection('learning_interventions').doc('int_001');

    await assertFails(
      intRef.update({
        status: 'completed',
      })
    );
  });

  // TEST 6: Standard user cannot impersonate reviewer through resolvedBy
  test('TEST 6: Standard user cannot impersonate reviewer through resolvedBy', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const issueRef = stdDb.collection('learning_issues').doc('issue_001');

    await assertFails(
      issueRef.update({
        resolvedBy: 'user_standard',
        status: 'resolved',
      })
    );
  });

  // TEST 7: Standard user cannot impersonate reviewer through assignedBy
  test('TEST 7: Standard user cannot impersonate reviewer through assignedBy', async () => {
    const stdDb = testEnv.authenticatedContext('user_standard', { reviewer: false }).firestore();
    const intRef = stdDb.collection('learning_interventions').doc('int_001');

    await assertFails(
      intRef.set({
        interventionId: 'int_002',
        assignedBy: 'user_standard',
        targetUserId: 'user_other',
      })
    );
  });

  // TEST 8: Reviewer can read global Learning Issue queue
  test('TEST 8: Reviewer with custom claim can read global Learning Issue queue', async () => {
    const revDb = testEnv.authenticatedContext('user_reviewer', { reviewer: true }).firestore();
    const query = revDb.collection('learning_issues');

    await assertSucceeds(query.get());
  });

  // TEST 9: Reviewer can resolve an issue
  test('TEST 9: Reviewer with custom claim can resolve an issue', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_issues').doc('issue_001').set({
        issueId: 'issue_001',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        moduleId: 'mod_001',
        topicId: 'top_001',
        issueType: 'topicNotTaught',
        description: 'Topic not taught',
        status: 'open',
        resolution: 'pending',
        evidenceSnapshot: { topicTitle: 'Topic 1' },
        createdAt: '2026-09-13T10:00:00Z',
      });
    });

    const revDb = testEnv.authenticatedContext('user_reviewer', { reviewer: true }).firestore();
    const issueRef = revDb.collection('learning_issues').doc('issue_001');

    await assertSucceeds(
      issueRef.update({
        issueId: 'issue_001',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        moduleId: 'mod_001',
        topicId: 'top_001',
        issueType: 'topicNotTaught',
        description: 'Topic not taught',
        status: 'resolved',
        resolution: 'correctiveSession',
        evidenceSnapshot: { topicTitle: 'Topic 1' },
        createdAt: '2026-09-13T10:00:00Z',
        resolvedBy: 'user_reviewer',
      })
    );
  });

  // TEST 10: Reviewer can dismiss an issue
  test('TEST 10: Reviewer with custom claim can dismiss an issue', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_issues').doc('issue_002').set({
        issueId: 'issue_002',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        moduleId: 'mod_001',
        topicId: 'top_001',
        issueType: 'topicNotTaught',
        description: 'Topic not taught',
        status: 'open',
        resolution: 'pending',
        evidenceSnapshot: { topicTitle: 'Topic 1' },
        createdAt: '2026-09-13T10:00:00Z',
      });
    });

    const revDb = testEnv.authenticatedContext('user_reviewer', { reviewer: true }).firestore();
    const issueRef = revDb.collection('learning_issues').doc('issue_002');

    await assertSucceeds(
      issueRef.update({
        issueId: 'issue_002',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        moduleId: 'mod_001',
        topicId: 'top_001',
        issueType: 'topicNotTaught',
        description: 'Topic not taught',
        status: 'dismissed',
        resolution: 'dismissed',
        evidenceSnapshot: { topicTitle: 'Topic 1' },
        createdAt: '2026-09-13T10:00:00Z',
        resolvedBy: 'user_reviewer',
      })
    );
  });

  // TEST 11: Reviewer can create an intervention
  test('TEST 11: Reviewer with custom claim can create an intervention', async () => {
    const revDb = testEnv.authenticatedContext('user_reviewer', { reviewer: true }).firestore();
    const intRef = revDb.collection('learning_interventions').doc('int_001');

    await assertSucceeds(
      intRef.set({
        interventionId: 'int_001',
        issueId: 'issue_001',
        targetUserId: 'mentor_001',
        assignedBy: 'user_reviewer',
        action: 'correctiveSession',
        status: 'pending',
      })
    );
  });

  // TEST 12: Reviewer can update an intervention
  test('TEST 12: Reviewer with custom claim can update an intervention', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_interventions').doc('int_001').set({
        interventionId: 'int_001',
        issueId: 'issue_001',
        targetUserId: 'mentor_001',
        assignedBy: 'user_reviewer',
        action: 'correctiveSession',
        status: 'pending',
      });
    });

    const revDb = testEnv.authenticatedContext('user_reviewer', { reviewer: true }).firestore();
    const intRef = revDb.collection('learning_interventions').doc('int_001');

    await assertSucceeds(
      intRef.update({
        status: 'completed',
        assignedBy: 'user_reviewer',
      })
    );
  });

  // TEST 13: Reporter can still create valid Learning Issues
  test('TEST 13: Reporter can create valid Learning Issue', async () => {
    const reporterDb = testEnv.authenticatedContext('learner_001').firestore();
    const issueRef = reporterDb.collection('learning_issues').doc('issue_new_001');

    await assertSucceeds(
      issueRef.set({
        issueId: 'issue_new_001',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        moduleId: 'mod_001',
        topicId: 'top_001',
        issueType: 'agreedOutcomeNotDelivered',
        description: 'Outcome incomplete',
        status: 'open',
        resolution: 'pending',
        createdAt: '2026-09-13T10:00:00Z',
      })
    );
  });

  // TEST 14: Reporter cannot modify immutable evidence
  test('TEST 14: Reporter cannot modify immutable evidence snapshot or issue parameters', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_issues').doc('issue_003').set({
        issueId: 'issue_003',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        topicId: 'top_001',
        description: 'Original description',
        issueType: 'agreedOutcomeNotDelivered',
        status: 'open',
        resolution: 'pending',
        createdAt: '2026-09-13T10:00:00Z',
      });
    });

    const reporterDb = testEnv.authenticatedContext('learner_001').firestore();
    const issueRef = reporterDb.collection('learning_issues').doc('issue_003');

    await assertFails(
      issueRef.update({
        description: 'Altered description by learner',
      })
    );
  });

  // TEST 15: Unrelated users cannot read another user's Learning Issue
  test('TEST 15: Unrelated user cannot read another user\'s Learning Issue', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_issues').doc('issue_private').set({
        issueId: 'issue_private',
        reporterId: 'learner_001',
        reportedUserId: 'mentor_001',
      });
    });

    const strangerDb = testEnv.authenticatedContext('stranger_999', { reviewer: false }).firestore();
    const issueRef = strangerDb.collection('learning_issues').doc('issue_private');

    await assertFails(issueRef.get());
  });

  // TEST 16: Existing Learning Plan security remains intact
  test('TEST 16: Existing Learning Plan security rules remain intact', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('learning_plans').doc('ex_active').set({
        planId: 'plan_active',
        exchangeId: 'ex_active',
        mentorId: 'mentor_1',
        learnerId: 'learner_1',
        status: 'active',
        skillName: 'Flutter Security',
        modules: [{ title: 'Module 1' }],
      });
    });

    const mentorDb = testEnv.authenticatedContext('mentor_1').firestore();
    const planRef = mentorDb.collection('learning_plans').doc('ex_active');

    // Structural modification of active plan must be rejected
    await assertFails(
      planRef.update({
        skillName: 'Altered Skill Scope',
      })
    );
  });
});
