// utils/keyword_generator.dart

List<String> generateKeywords(String name) {
  List<String> keywords = [];
  List<String> words = name.toLowerCase().split(' ');
  for (int i = 0; i < words.length; i++) {
    for (int j = 1; j <= words[i].length; j++) {
      keywords.add(words[i].substring(0, j));
    }
  }
  return keywords;
}
