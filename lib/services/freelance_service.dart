import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/freelance_project_model.dart';
import '../models/portfolio_item_model.dart';
import 'user_service.dart';

class FreelanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final Uuid _uuid = const Uuid();

  // Create new project
  Future<FreelanceProjectModel> createProject({
    required String title,
    required String description,
    required List<String> requiredSkills,
    required ProjectDifficulty difficulty,
    required double budget,
    required int estimatedDuration,
    DateTime? deadline,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final client = await _userService.getUserById(uid);
      if (client == null) throw Exception('User not found');

      final project = FreelanceProjectModel(
        id: _uuid.v4(),
        clientId: uid,
        clientName: client.fullName,
        clientImageUrl: client.profileImageUrl,
        title: title,
        description: description,
        requiredSkills: requiredSkills,
        difficulty: difficulty,
        budget: budget,
        estimatedDuration: estimatedDuration,
        deadline: deadline,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('freelance_projects')
          .doc(project.id)
          .set(project.toMap());

      return project;
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all open projects
  Stream<List<FreelanceProjectModel>> getOpenProjects({
    List<String>? skills,
    ProjectDifficulty? difficulty,
  }) {
    Query query = _firestore
        .collection('freelance_projects')
        .where('status', isEqualTo: ProjectStatus.open.name)
        .orderBy('createdAt', descending: true);

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    return query.snapshots().map((snapshot) {
      var projects = snapshot.docs
          .map((doc) => FreelanceProjectModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by skills if provided
      if (skills != null && skills.isNotEmpty) {
        projects = projects.where((project) {
          return project.requiredSkills
              .any((skill) => skills.contains(skill));
        }).toList();
      }

      return projects;
    });
  }

  // Get my posted projects
  Stream<List<FreelanceProjectModel>> getMyProjects() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('freelance_projects')
        .where('clientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FreelanceProjectModel.fromMap(doc.data()))
            .toList());
  }

  // Get projects assigned to me
  Stream<List<FreelanceProjectModel>> getAssignedProjects() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('freelance_projects')
        .where('assignedToId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FreelanceProjectModel.fromMap(doc.data()))
            .toList());
  }

  // Apply to project
  Future<void> applyToProject(String projectId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore.collection('freelance_projects').doc(projectId).update({
        'applicantIds': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw Exception('Failed to apply to project: $e');
    }
  }

  // Assign project to freelancer
  Future<void> assignProject({
    required String projectId,
    required String freelancerId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      final projectDoc = await _firestore
          .collection('freelance_projects')
          .doc(projectId)
          .get();
      
      final project = FreelanceProjectModel.fromMap(projectDoc.data()!);

      // Verify requester is the client
      if (project.clientId != uid) {
        throw Exception('Only the client can assign this project');
      }

      final freelancer = await _userService.getUserById(freelancerId);
      if (freelancer == null) throw Exception('Freelancer not found');

      await _firestore.collection('freelance_projects').doc(projectId).update({
        'assignedToId': freelancerId,
        'assignedToName': freelancer.fullName,
        'assignedToImageUrl': freelancer.profileImageUrl,
        'status': ProjectStatus.inProgress.name,
        'startedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to assign project: $e');
    }
  }

  // Submit project deliverable
  Future<void> submitDeliverable({
    required String projectId,
    required String deliverableUrl,
  }) async {
    try {
      await _firestore.collection('freelance_projects').doc(projectId).update({
        'deliverableUrl': deliverableUrl,
        'status': ProjectStatus.underReview.name,
      });
    } catch (e) {
      throw Exception('Failed to submit deliverable: $e');
    }
  }

  // Complete project and release payment
  Future<void> completeProject({
    required String projectId,
    required double rating,
    String? review,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      final projectDoc = await _firestore
          .collection('freelance_projects')
          .doc(projectId)
          .get();
      
      final project = FreelanceProjectModel.fromMap(projectDoc.data()!);

      // Verify requester is the client
      if (project.clientId != uid) {
        throw Exception('Only the client can complete this project');
      }

      if (project.assignedToId == null) {
        throw Exception('Project not assigned to anyone');
      }

      await _firestore.collection('freelance_projects').doc(projectId).update({
        'status': ProjectStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
        'rating': rating,
        'review': review,
        'isPaid': true,
      });

      // Update freelancer stats
      await _userService.updateRating(project.assignedToId!, rating);
      await _userService.incrementCompletedProjects(project.assignedToId!);
      
      // Award XP based on project difficulty
      int xpReward = 100;
      switch (project.difficulty) {
        case ProjectDifficulty.beginner:
          xpReward = 100;
          break;
        case ProjectDifficulty.intermediate:
          xpReward = 250;
          break;
        case ProjectDifficulty.advanced:
          xpReward = 500;
          break;
      }
      
      await _userService.addXP(project.assignedToId!, xpReward);

      // Add to freelancer's portfolio
      await _addToPortfolio(project, rating, review);
    } catch (e) {
      throw Exception('Failed to complete project: $e');
    }
  }

  // Add completed project to portfolio
  Future<void> _addToPortfolio(
    FreelanceProjectModel project,
    double rating,
    String? review,
  ) async {
    try {
      if (project.assignedToId == null) return;

      final portfolioItem = PortfolioItemModel(
        id: _uuid.v4(),
        userId: project.assignedToId!,
        type: 'project',
        title: project.title,
        description: project.description,
        skills: project.requiredSkills,
        completedAt: DateTime.now(),
        rating: rating,
        review: review,
        imageUrl: project.deliverableUrl,
        metadata: {
          'projectId': project.id,
          'clientName': project.clientName,
          'budget': project.budget,
          'difficulty': project.difficulty.name,
        },
      );

      await _firestore
          .collection('portfolio')
          .doc(portfolioItem.id)
          .set(portfolioItem.toMap());
    } catch (e) {
      throw Exception('Failed to add to portfolio: $e');
    }
  }

  // Cancel project
  Future<void> cancelProject(String projectId) async {
    try {
      final uid = _auth.currentUser?.uid;
      final projectDoc = await _firestore
          .collection('freelance_projects')
          .doc(projectId)
          .get();
      
      final project = FreelanceProjectModel.fromMap(projectDoc.data()!);

      // Only client or assigned freelancer can cancel
      if (project.clientId != uid && project.assignedToId != uid) {
        throw Exception('You cannot cancel this project');
      }

      await _firestore.collection('freelance_projects').doc(projectId).update({
        'status': ProjectStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel project: $e');
    }
  }

  // Get project applicants
  Future<List<dynamic>> getProjectApplicants(String projectId) async {
    try {
      final projectDoc = await _firestore
          .collection('freelance_projects')
          .doc(projectId)
          .get();
      
      final project = FreelanceProjectModel.fromMap(projectDoc.data()!);
      
      final applicants = <dynamic>[];
      for (final applicantId in project.applicantIds) {
        final user = await _userService.getUserById(applicantId);
        if (user != null) {
          applicants.add(user);
        }
      }
      
      return applicants;
    } catch (e) {
      throw Exception('Failed to get applicants: $e');
    }
  }
}
