String getChatId(String uid1, String uid2) {
  List<String> ids = [uid1, uid2];
  ids.sort(); // This is the magic: it forces "A_B" order every time.
  return ids.join('_');
}