import 'package:flutter/material.dart';

/// Widget that renders a string with first occurrence sub-string highlighting.
/// Widget that renders a string with first occurrence sub-string highlighting.
class SubstringHighlight extends StatelessWidget {
  /// Creates a SubstringHighlight widget.
  ///
  /// The [text] parameter is required and represents the text to be displayed.
  /// Either [term] or [terms] must be provided for highlighting.
  const SubstringHighlight({
    Key? key,
    this.caseSensitive = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.term,
    this.terms,
    required this.text,
    this.textAlign = TextAlign.left,
    this.textStyle = const TextStyle(
      color: Colors.black,
    ),
    this.textStyleHighlight = const TextStyle(
      color: Colors.red,
    ),
    this.wordDelimiters = ' .,;?!<>[]~`@#\$%^&*()+-=|/_',
    this.words = false,
  })  : assert(term != null || terms != null),
        super(key: key);

  /// Whether the search should be case-sensitive.
  final bool caseSensitive;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// A single term to search for within the text.
  final String? term;

  /// A list of terms to search for within the text.
  final List<String>? terms;

  /// The text to be displayed and searched.
  final String text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The style to use for non-highlighted text.
  final TextStyle textStyle;

  /// The style to use for highlighted text.
  final TextStyle textStyleHighlight;

  /// The set of characters that are used as word boundaries.
  final String wordDelimiters;

  /// Whether to match only whole words.
  final bool words;

  @override
  Widget build(BuildContext context) {
    final String textLC = caseSensitive ? text : text.toLowerCase();

    // Combine term and terms
    final List<String> termList = [term ?? '', ...(terms ?? [])];

    // Remove empty search terms and apply case sensitivity
    final List<String> termListLC = termList
        .where((s) => s.isNotEmpty)
        .map((s) => caseSensitive ? s : s.toLowerCase())
        .toList();

    List<InlineSpan> children = [];

    // Find the first occurrence of any term
    int? firstOccurrence;
    String? matchedTerm;

    for (String searchTerm in termListLC) {
      int index = textLC.indexOf(searchTerm);
      if (index >= 0) {
        if (words) {
          bool isValidWord = true;

          // Check preceding character
          if (index > 0 && !wordDelimiters.contains(textLC[index - 1])) {
            isValidWord = false;
          }

          // Check following character
          int followingIdx = index + searchTerm.length;
          if (followingIdx < textLC.length &&
              !wordDelimiters.contains(textLC[followingIdx])) {
            isValidWord = false;
          }

          if (!isValidWord) continue;
        }

        if (firstOccurrence == null || index < firstOccurrence) {
          firstOccurrence = index;
          matchedTerm = searchTerm;
        }
      }
    }

    if (firstOccurrence != null && matchedTerm != null) {
      // Add text before the match
      if (firstOccurrence > 0) {
        children.add(TextSpan(
            text: text.substring(0, firstOccurrence), style: textStyle));
      }

      // Add the highlighted match
      children.add(TextSpan(
          text: text.substring(
              firstOccurrence, firstOccurrence + matchedTerm.length),
          style: textStyleHighlight));

      // Add remaining text
      if (firstOccurrence + matchedTerm.length < text.length) {
        children.add(TextSpan(
            text: text.substring(firstOccurrence + matchedTerm.length),
            style: textStyle));
      }
    } else {
      // No match found, return the entire text unhighlighted
      children.add(TextSpan(text: text, style: textStyle));
    }

    return Text.rich(TextSpan(children: children),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        textScaler: MediaQuery.of(context).textScaler);
  }
}
