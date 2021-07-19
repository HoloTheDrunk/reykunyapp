//=== Ending

bool endsInVowel(String noun) {
  String lastChar = noun[noun.length - 1];
  return lastChar == 'a' ||
      lastChar == 'ä' ||
      lastChar == 'e' ||
      lastChar == 'é' ||
      lastChar == 'i' ||
      lastChar == 'ì' ||
      lastChar == 'o' ||
      lastChar == 'u';
}

bool endsInConsonant(String noun) {
  String lastTwoChars = noun.substring(noun.length - 2);
  return !endsInVowel(lastTwoChars) &&
      lastTwoChars != "aw" &&
      lastTwoChars != "ay" &&
      lastTwoChars != "ew" &&
      lastTwoChars != "ey";
}

//==== Case

String subjective(String noun) {
  return noun + '-';
}

String agentive(String noun) {
  if (endsInVowel(noun)) {
    return noun + '-l';
  } else {
    return noun + '-ìl';
  }
}

String patientive(String noun) {
  if (endsInVowel(noun)) {
    return noun + "-t(i)";
  } else {
    if (endsInConsonant(noun)) {
      return noun + "-it/ti";
    } else {
      if (noun.substring(-1) == "y") {
        if (noun.substring(-2) == "ey") {
          return noun + "-t(i)";
        } else {
          return noun + "-it/t(i)";
        }
      } else {
        return noun + "-it/ti";
      }
    }
  }
}

String dative(String noun) {
  if (endsInVowel(noun)) {
    return noun + "-r(u)";
  } else {
    if (endsInConsonant(noun)) {
      if (noun.substring(-1) == "'") {
        return noun + "-ur/ru";
      }
      return noun + "-ur";
    } else {
      if (noun.substring(-1) == "w") {
        if (noun.substring(-2) == "ew") {
          return noun + "-r(u)";
        } else {
          return noun + "-ur/r(u)";
        }
      } else {
        return noun + "-ru/ur";
      }
    }
  }
}

String genitive(String noun) {
  if (endsInVowel(noun)) {
    if (noun.substring(-1) == "o" || noun.substring(-1) == "u") {
      return noun + "-ä";
    } else {
      if (noun.substring(-2) == "ia") {
        return noun.substring(0, -1) + "-ä";
      } else {
        if (noun.toLowerCase().substring(-9) == "omatikaya") {
          return noun + "-ä";
        } else {
          return noun + "-yä";
        }
      }
    }
  } else {
    return noun + "-ä";
  }
}

String topical(String noun) {
  if (endsInVowel(noun)) {
    return noun + "-ri";
  } else {
    if (endsInConsonant(noun)) {
      return noun + "-ìri";
    } else {
      return noun + "-ri";
    }
  }
}

//==== Multiplicity

String singular(String noun) {
  return '-' + noun;
}

String dual(String noun) {
  var stem = lenite(noun);
  if (stem[0].toLowerCase() == "e") {
    return "m-" + stem;
  } else {
    return "me-" + stem;
  }
}

String trial(String noun) {
  String stem = lenite(noun);
  if (stem[0].toLowerCase() == "e") {
    return "px-" + stem;
  } else {
    return "pxe-" + stem;
  }
}

String plural(String noun) {
  // is short plural allowed?
  if (lenitable(noun) && noun != "'u") {
    // 'u doesn't have short plural
    return "(ay-)" + lenite(noun);
  } else {
    return "ay-" + lenite(noun);
  }
}

bool lenitable(String word) {
  return lenite(word) != word;
}

String lenite(String word) {
  // 'rr and 'll are not lenited, since rr and ll cannot start a syllable
  if (word.toLowerCase().substring(0, 3) == "'ll" ||
      word.toLowerCase().substring(0, 3) == "'rr") {
    return word;
  }

  word = lreplace(word, "ts", "{s}");
  word = lreplace(word, "kx", "{k}");
  word = lreplace(word, "px", "{p}");
  word = lreplace(word, "tx", "{t}");
  word = lreplace(word, "'", "");
  word = lreplace(word, "k", "{h}");
  word = lreplace(word, "p", "{f}");
  word = lreplace(word, "t", "{s}");

  return word;
}

String lreplace(String word, String find, String replace) {
  if (word.substring(0, find.length) == find) {
    return replace + word.substring(find.length);
  } else {
    return word;
  }
}
