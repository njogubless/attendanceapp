

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _coursesCollection => _firestore.collection('courses');
  CollectionReference get _unitsCollection => _firestore.collection('units');
  CollectionReference get _registrationsCollection => _firestore.collection('registrations');
  CollectionReference get _attendanceCollection => _firestore.collection('attendance');

  // Auth methods
  Future<User?> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<User?> signUp(String email, String password, String name, String userType) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = userCredential.user;
    if (user != null) {
      await _usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'userType': userType,
        'profileImageUrl': null,
        'createdAt': Timestamp.now(),
      });
    }
    
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User methods
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) return null;
    
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Course methods
  Future<String> createCourse(CourseModel course) async {
    final docRef = _coursesCollection.doc();
    final courseWithId = CourseModel(
      id: docRef.id,
      name: course.name,
      code: course.code,
      lecturerId: course.lecturerId,
      unitIds: course.unitIds,
      createdAt: DateTime.now(),
    );
    
    await docRef.set(courseWithId.toJson());
    return docRef.id;
  }

  Future<List<CourseModel>> getCoursesByLecturerId(String lecturerId) async {
    final snapshot = await _coursesCollection
        .where('lecturerId', isEqualTo: lecturerId)
        .get();
    
    return snapshot.docs
        .map((doc) => CourseModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<CourseModel?> getCourseById(String courseId) async {
    final doc = await _coursesCollection.doc(courseId).get();
    if (!doc.exists) return null;
    
    return CourseModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Unit methods
  Future<String> createUnit(UnitModel unit) async {
    final docRef = _unitsCollection.doc();
    final unitWithId = UnitModel(
      id: docRef.id,
      name: unit.name,
      code: unit.code,
      courseId: unit.courseId,
      lecturerId: unit.lecturerId,
      venue: unit.venue,
      schedules: unit.schedules,
      createdAt: DateTime.now(),
    );
    
    await docRef.set(unitWithId.toJson());
    
    // Update course with new unit ID
    await _coursesCollection.doc(unit.courseId).update({
      'unitIds': FieldValue.arrayUnion([docRef.id]),
    });
    
    return docRef.id;
  }

  Future<List<UnitModel>> getUnitsByCourseId(String courseId) async {
    final snapshot = await _unitsCollection
        .where('courseId', isEqualTo: courseId)
        .get();
    
    return snapshot.docs
        .map((doc) => UnitModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<UnitModel?> getUnitById(String unitId) async {
    final doc = await _unitsCollection.doc(unitId).get();
    if (!doc.exists) return null;
    
    return UnitModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Registration methods
  Future<String> registerForCourse(String studentId, String courseId) async {
    final docRef = _registrationsCollection.doc();
    final registration = CourseRegistrationModel(
      id: docRef.id,
      studentId: studentId,
      courseId: courseId,
      status: 'pending',
      lecturerComment: null,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
    
    await docRef.set(registration.toJson());
    return docRef.id;
  }

  Future<void> updateRegistrationStatus(String registrationId, String status, String? comment) async {
    await _registrationsCollection.doc(registrationId).update({
      'status': status,
      'lecturerComment': comment,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<CourseRegistrationModel>> getPendingRegistrationsByLecturerId(String lecturerId) async {
    // Get all courses by lecturer
    final courses = await getCoursesByLecturerId(lecturerId);
    final courseIds = courses.map((c) => c.id).toList();
    
    // Get registrations for those courses
    final snapshot = await _registrationsCollection
        .where('courseId', whereIn: courseIds)
        .where('status', isEqualTo: 'pending')
        .get();
    
    return snapshot.docs
        .map((doc) => CourseRegistrationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourseRegistrationModel>> getRegistrationsByStudentId(String studentId) async {
    final snapshot = await _registrationsCollection
        .where('studentId', isEqualTo: studentId)
        .get();
    
    return snapshot.docs
        .map((doc) => CourseRegistrationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Attendance methods
  Future<String> recordAttendance(AttendanceModel attendance) async {
    final docRef = _attendanceCollection.doc();
    final attendanceWithId = AttendanceModel(
      id: docRef.id,
      unitId: attendance.unitId,
      userId: attendance.userId,
      userType: attendance.userType,
      userName: attendance.userName,
      userEmail: attendance.userEmail,
      courseId: attendance.courseId,
      courseName: attendance.courseName,
      courseCode: attendance.courseCode,
      venue: attendance.venue,
      date: attendance.date,
      timestamp: DateTime.now(),
    );
    
    await docRef.set(attendanceWithId.toJson());
    return docRef.id;
  }

  Future<List<AttendanceModel>> getAttendanceByUnitId(String unitId, {DateTime? date}) async {
    Query query = _attendanceCollection.where('unitId', isEqualTo: unitId);
    
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceByStudentId(String studentId, {String? courseId}) async {
    Query query = _attendanceCollection
        .where('userId', isEqualTo: studentId)
        .where('userType', isEqualTo: 'student');
    
    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceReport({String? courseId, String? unitId, DateTime? date}) async {
    Query query = _attendanceCollection;
    
    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    
    if (unitId != null) {
      query = query.where('unitId', isEqualTo: unitId);
    }
    
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}