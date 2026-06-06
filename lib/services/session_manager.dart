class SessionManager {
  // Private constructor for singleton pattern
  SessionManager._privateConstructor();
  static final SessionManager instance = SessionManager._privateConstructor();

  // Runtime active user profile map configurations cached from login
  Map<String, dynamic>? currentUserProfile;

  void clearSession() {
    currentUserProfile = null;
  }
}