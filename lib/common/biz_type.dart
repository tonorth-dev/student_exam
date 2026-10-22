class BizType {
  static const int militaryCivilian = 1;
  static const int directOfficer = 2;

  static int normalize(dynamic value) {
    final parsed = value is num ? value.toInt() : null;
    if (parsed == directOfficer) {
      return directOfficer;
    }
    return militaryCivilian;
  }

  static String label(int bizType) {
    if (bizType == directOfficer) {
      return "直招军官";
    }
    return "军队文职";
  }
}
