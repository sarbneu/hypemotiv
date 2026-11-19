/// Quote generator service - generates motivational quotes for text-to-speech.
library;
import 'dart:math';

import 'package:hypemotiv/models/quote.dart';

class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;

  QuoteService._internal();

  final Random _random = Random();
  final List<Map<String, String>> _quotes = [
    {
      'text': 'Wake up. The morning belongs to those who rise before it. Your future is waiting for you.',
      'author': 'HypeMotiv',
    },
    {
      'text': 'Success is not final, failure is not fatal: It is the courage to continue that counts.',
      'author': 'Winston Churchill',
    },
    {
      'text': 'The best time to plant a tree was 20 years ago. The second best time is now.',
      'author': 'Chinese Proverb',
    },
    {
      'text': 'Don\'t watch the clock; do what it\'s doing. Keep going.',
      'author': 'Sam Levenson',
    },
    {
      'text': 'Believe you can and you\'re halfway there.',
      'author': 'Theodore Roosevelt',
    },
    {
      'text': 'Your limitation—it\'s only your imagination. Your task—it\'s nothing but motivation.',
      'author': 'HypeMotiv',
    },
    {
      'text': 'Morning is an opportunity to reset. Start fresh, start strong.',
      'author': 'HypeMotiv',
    },
    {
      'text': 'The only way to do great work is to love what you do.',
      'author': 'Steve Jobs',
    },
    {
      'text': 'Discipline is choosing between what you want now and what you want most.',
      'author': 'Abraham Lincoln',
    },
    {
      'text': 'Small steps every day add up to big changes over time.',
      'author': 'HypeMotiv',
    },
    {
      'text': 'You are never too old to set another goal or to dream a new dream.',
      'author': 'C.S. Lewis',
    },
    {
      'text': 'Hard work beats talent when talent doesn\'t work hard.',
      'author': 'Tim Notke',
    },
    {
      'text': 'It always seems impossible until it\'s done.',
      'author': 'Nelson Mandela',
    },
    {
      'text': 'Morning pages are a way of rebooting your brain.',
      'author': 'Julia Cameron',
    },
    {
      'text': 'The secret of getting ahead is getting started.',
      'author': 'Mark Twain',
    },
  ];

  /// Get a random quote.
  Quote getRandomQuote() {
    final idx = _random.nextInt(_quotes.length);
    final q = _quotes[idx];
    return Quote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}_$idx',
      text: q['text']!,
      author: q['author']!,
    );
  }

  /// Get a quote by index (for testing).
  Quote getQuoteByIndex(int index) {
    final q = _quotes[index % _quotes.length];
    return Quote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}_$index',
      text: q['text']!,
      author: q['author']!,
    );
  }

  /// Generate multiple quotes for a challenge.
  List<Quote> generateChallengeQuotes(int count) {
    final result = <Quote>[];
    for (int i = 0; i < count; i++) {
      result.add(getRandomQuote());
    }
    return result;
  }

  /// Get all available quotes (for reference).
  List<Map<String, String>> getAllQuotes() => List.from(_quotes);
}

/// Quote service initialization.
extension QuoteServiceInit on QuoteService {
  /// Initialize the quote service.
  static Future<void> init() async {
    // Nothing to initialize for quote service
  }
}
