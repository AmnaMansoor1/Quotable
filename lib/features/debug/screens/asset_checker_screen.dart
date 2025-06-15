import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AssetCheckerScreen extends StatefulWidget {
  const AssetCheckerScreen({super.key});

  @override
  State<AssetCheckerScreen> createState() => _AssetCheckerScreenState();
}

class _AssetCheckerScreenState extends State<AssetCheckerScreen> {
  Map<String, Map<String, dynamic>> _assetStatus = {};
  bool _isLoading = false;

  final List<String> _requiredAssets = [
    'alone', 'angry', 'attitude', 'breakup', 'emotional',
    'family', 'friends', 'funny', 'love', 'motivational',
    'success', 'wisdom'
  ];

  @override
  void initState() {
    super.initState();
    _checkAllAssets();
  }

  Future<void> _checkAllAssets() async {
    setState(() {
      _isLoading = true;
    });

    print('🔍 Checking all asset files...');
    final status = <String, Map<String, dynamic>>{};

    for (String category in _requiredAssets) {
      final assetPath = 'assets/quotes/${category}.json';
      
      try {
        print('📂 Checking: $assetPath');
        final content = await rootBundle.loadString(assetPath);
        
        if (content.isEmpty) {
          status[category] = {
            'exists': false,
            'error': 'File exists but is empty',
            'content': '',
            'quoteCount': 0,
          };
        } else {
          try {
            final jsonData = json.decode(content);
            final quoteCount = jsonData is List ? jsonData.length : 0;
            
            status[category] = {
              'exists': true,
              'error': null,
              'content': content.substring(0, content.length > 100 ? 100 : content.length),
              'quoteCount': quoteCount,
            };
            print('✅ $category: $quoteCount quotes found');
          } catch (e) {
            status[category] = {
              'exists': true,
              'error': 'Invalid JSON format: $e',
              'content': content.substring(0, content.length > 100 ? 100 : content.length),
              'quoteCount': 0,
            };
          }
        }
      } catch (e) {
        status[category] = {
          'exists': false,
          'error': e.toString(),
          'content': '',
          'quoteCount': 0,
        };
        print('❌ $category: $e');
      }
    }

    setState(() {
      _assetStatus = status;
      _isLoading = false;
    });
  }

  String _createSampleQuotes(String category) {
    final sampleQuotes = {
      'motivational': [
        {"id": "mot_1", "text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
        {"id": "mot_2", "text": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"},
        {"id": "mot_3", "text": "Your time is limited, don't waste it living someone else's life.", "author": "Steve Jobs"},
        {"id": "mot_4", "text": "Stay hungry, stay foolish.", "author": "Steve Jobs"},
        {"id": "mot_5", "text": "The future belongs to those who believe in the beauty of their dreams.", "author": "Eleanor Roosevelt"},
        {"id": "mot_6", "text": "It is during our darkest moments that we must focus to see the light.", "author": "Aristotle"},
        {"id": "mot_7", "text": "Success is not final, failure is not fatal: it is the courage to continue that counts.", "author": "Winston Churchill"},
        {"id": "mot_8", "text": "The way to get started is to quit talking and begin doing.", "author": "Walt Disney"},
        {"id": "mot_9", "text": "Don't let yesterday take up too much of today.", "author": "Will Rogers"},
        {"id": "mot_10", "text": "You learn more from failure than from success.", "author": "Unknown"},
        {"id": "mot_11", "text": "If you are working on something exciting that you really care about, you don't have to be pushed.", "author": "Steve Jobs"},
        {"id": "mot_12", "text": "Don't be afraid to give up the good to go for the great.", "author": "John D. Rockefeller"},
        {"id": "mot_13", "text": "The only impossible journey is the one you never begin.", "author": "Tony Robbins"},
        {"id": "mot_14", "text": "In the middle of difficulty lies opportunity.", "author": "Albert Einstein"},
        {"id": "mot_15", "text": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
        {"id": "mot_16", "text": "The only person you are destined to become is the person you decide to be.", "author": "Ralph Waldo Emerson"},
        {"id": "mot_17", "text": "Go confidently in the direction of your dreams.", "author": "Henry David Thoreau"},
        {"id": "mot_18", "text": "When you have a dream, you've got to grab it and never let go.", "author": "Carol Burnett"},
        {"id": "mot_19", "text": "Nothing is impossible. The word itself says 'I'm possible!'", "author": "Audrey Hepburn"},
        {"id": "mot_20", "text": "There is nothing impossible to they who will try.", "author": "Alexander the Great"}
      ],
      'success': [
        {"id": "suc_1", "text": "Success is not the key to happiness. Happiness is the key to success.", "author": "Albert Schweitzer"},
        {"id": "suc_2", "text": "Don't be afraid to give up the good to go for the great.", "author": "John D. Rockefeller"},
        {"id": "suc_3", "text": "The way to get started is to quit talking and begin doing.", "author": "Walt Disney"},
        {"id": "suc_4", "text": "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.", "author": "Winston Churchill"},
        {"id": "suc_5", "text": "Don't let yesterday take up too much of today.", "author": "Will Rogers"},
        {"id": "suc_6", "text": "You learn more from failure than from success. Don't let it stop you. Failure builds character.", "author": "Unknown"},
        {"id": "suc_7", "text": "It's not whether you get knocked down, it's whether you get up.", "author": "Vince Lombardi"},
        {"id": "suc_8", "text": "If you are working on something that you really care about, you don't have to be pushed.", "author": "Steve Jobs"},
        {"id": "suc_9", "text": "Entrepreneurs are great at dealing with uncertainty and also very good at minimizing risk.", "author": "Mohnish Pabrai"},
        {"id": "suc_10", "text": "We generate fears while we sit. We overcome them by action.", "author": "Dr. Henry Link"},
        {"id": "suc_11", "text": "Whether you think you can or think you can't, you're right.", "author": "Henry Ford"},
        {"id": "suc_12", "text": "The only impossible journey is the one you never begin.", "author": "Tony Robbins"},
        {"id": "suc_13", "text": "In the middle of difficulty lies opportunity.", "author": "Albert Einstein"},
        {"id": "suc_14", "text": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
        {"id": "suc_15", "text": "Act as if what you do makes a difference. It does.", "author": "William James"},
        {"id": "suc_16", "text": "Success is walking from failure to failure with no loss of enthusiasm.", "author": "Winston Churchill"},
        {"id": "suc_17", "text": "The only person you are destined to become is the person you decide to be.", "author": "Ralph Waldo Emerson"},
        {"id": "suc_18", "text": "Go confidently in the direction of your dreams.", "author": "Henry David Thoreau"},
        {"id": "suc_19", "text": "When you have a dream, you've got to grab it and never let go.", "author": "Carol Burnett"},
        {"id": "suc_20", "text": "Life is what happens to you while you're busy making other plans.", "author": "John Lennon"}
      ],
      'wisdom': [
        {"id": "wis_1", "text": "The only true wisdom is in knowing you know nothing.", "author": "Socrates"},
        {"id": "wis_2", "text": "The fool doth think he is wise, but the wise man knows himself to be a fool.", "author": "William Shakespeare"},
        {"id": "wis_3", "text": "Yesterday is history, tomorrow is a mystery, today is a gift of God, which is why we call it the present.", "author": "Bill Keane"},
        {"id": "wis_4", "text": "A wise man can learn more from a foolish question than a fool can learn from a wise answer.", "author": "Bruce Lee"},
        {"id": "wis_5", "text": "The journey of a thousand miles begins with one step.", "author": "Lao Tzu"},
        {"id": "wis_6", "text": "That which does not kill us makes us stronger.", "author": "Friedrich Nietzsche"},
        {"id": "wis_7", "text": "Life is what happens to you while you're busy making other plans.", "author": "John Lennon"},
        {"id": "wis_8", "text": "When the going gets tough, the tough get going.", "author": "Joe Kennedy"},
        {"id": "wis_9", "text": "You must be the change you wish to see in the world.", "author": "Mahatma Gandhi"},
        {"id": "wis_10", "text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
        {"id": "wis_11", "text": "Life is really simple, but we insist on making it complicated.", "author": "Confucius"},
        {"id": "wis_12", "text": "The unexamined life is not worth living.", "author": "Socrates"},
        {"id": "wis_13", "text": "Turn your wounds into wisdom.", "author": "Oprah Winfrey"},
        {"id": "wis_14", "text": "The way I see it, if you want the rainbow, you gotta put up with the rain.", "author": "Dolly Parton"},
        {"id": "wis_15", "text": "Do not go where the path may lead, go instead where there is no path and leave a trail.", "author": "Ralph Waldo Emerson"},
        {"id": "wis_16", "text": "In three words I can sum up everything I've learned about life: it goes on.", "author": "Robert Frost"},
        {"id": "wis_17", "text": "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", "author": "Ralph Waldo Emerson"},
        {"id": "wis_18", "text": "Here's to the crazy ones. The misfits. The rebels.", "author": "Steve Jobs"},
        {"id": "wis_19", "text": "Be yourself; everyone else is already taken.", "author": "Oscar Wilde"},
        {"id": "wis_20", "text": "Two things are infinite: the universe and human stupidity; and I'm not sure about the universe.", "author": "Albert Einstein"}
      ],
      'friends': [
        {"id": "fri_1", "text": "A friend is someone who knows all about you and still loves you.", "author": "Elbert Hubbard"},
        {"id": "fri_2", "text": "Friendship is born at that moment when one person says to another, 'What! You too? I thought I was the only one.'", "author": "C.S. Lewis"},
        {"id": "fri_3", "text": "A true friend is one who overlooks your failures and tolerates your success.", "author": "Doug Larson"},
        {"id": "fri_4", "text": "A good friend is like a four-leaf clover; hard to find and lucky to have.", "author": "Irish Proverb"},
        {"id": "fri_5", "text": "There is nothing I would not do for those who are really my friends.", "author": "Jane Austen"},
        {"id": "fri_6", "text": "True friendship comes when the silence between two people is comfortable.", "author": "David Tyson"},
        {"id": "fri_7", "text": "Friends are the siblings God never gave us.", "author": "Mencius"},
        {"id": "fri_8", "text": "A friend is what the heart needs all the time.", "author": "Henry Van Dyke"},
        {"id": "fri_9", "text": "Friendship is the only cement that will ever hold the world together.", "author": "Woodrow Wilson"},
        {"id": "fri_10", "text": "A true friend is someone who thinks that you are a good egg even though he knows that you are slightly cracked.", "author": "Bernard Meltzer"},
        {"id": "fri_11", "text": "Friends show their love in times of trouble, not in happiness.", "author": "Euripides"},
        {"id": "fri_12", "text": "Friendship is not about who you've known the longest. It's about who walked into your life and said 'I'm here for you' and proved it.", "author": "Unknown"},
        {"id": "fri_13", "text": "The greatest gift of life is friendship, and I have received it.", "author": "Hubert H. Humphrey"},
        {"id": "fri_14", "text": "A friend is someone who gives you total freedom to be yourself.", "author": "Jim Morrison"},
        {"id": "fri_15", "text": "Friends are those rare people who ask how we are and then wait to hear the answer.", "author": "Ed Cunningham"},
        {"id": "fri_16", "text": "A single rose can be my garden... a single friend, my world.", "author": "Leo Buscaglia"},
        {"id": "fri_17", "text": "Friendship marks a life even more deeply than love.", "author": "Elie Wiesel"},
        {"id": "fri_18", "text": "The most beautiful discovery true friends make is that they can grow separately without growing apart.", "author": "Elisabeth Foley"},
        {"id": "fri_19", "text": "In the cookie of life, friends are the chocolate chips.", "author": "Salman Rushdie"},
        {"id": "fri_20", "text": "A friend is one that knows you as you are, understands where you have been, accepts what you have become, and still, gently allows you to grow.", "author": "William Shakespeare"}
      ],
      'funny': [
        {"id": "fun_1", "text": "I'm not superstitious, but I am a little stitious.", "author": "Michael Scott"},
        {"id": "fun_2", "text": "The trouble with having an open mind, of course, is that people will insist on coming along and trying to put things in it.", "author": "Terry Pratchett"},
        {"id": "fun_3", "text": "I haven't slept for ten days, because that would be too long.", "author": "Mitch Hedberg"},
        {"id": "fun_4", "text": "I used to think I was indecisive, but now I'm not so sure.", "author": "Unknown"},
        {"id": "fun_5", "text": "The early bird might get the worm, but the second mouse gets the cheese.", "author": "Willie Nelson"},
        {"id": "fun_6", "text": "I told my wife the truth. I told her I was seeing a psychiatrist. Then she told me the truth: that she was seeing a psychiatrist, two plumbers, and a bartender.", "author": "Rodney Dangerfield"},
        {"id": "fun_7", "text": "Behind every great man is a woman rolling her eyes.", "author": "Jim Carrey"},
        {"id": "fun_8", "text": "Do not take life too seriously. You will never get out of it alive.", "author": "Elbert Hubbard"},
        {"id": "fun_9", "text": "Everyone should be able to do one card trick, tell two jokes, and recite three poems, in case they are ever trapped in an elevator.", "author": "Lemony Snicket"},
        {"id": "fun_10", "text": "The difference between stupidity and genius is that genius has its limits.", "author": "Albert Einstein"},
        {"id": "fun_11", "text": "If you think you are too small to make a difference, try sleeping with a mosquito.", "author": "Dalai Lama"},
        {"id": "fun_12", "text": "A day without sunshine is like, you know, night.", "author": "Steve Martin"},
        {"id": "fun_13", "text": "The road to success is dotted with many tempting parking spaces.", "author": "Will Rogers"},
        {"id": "fun_14", "text": "I'm writing a book. I've got the page numbers done.", "author": "Steven Wright"},
        {"id": "fun_15", "text": "If at first you don't succeed, then skydiving definitely isn't for you.", "author": "Steven Wright"},
        {"id": "fun_16", "text": "Money talks...but all mine ever says is good-bye.", "author": "Unknown"},
        {"id": "fun_17", "text": "I'm not arguing, I'm just explaining why I'm right.", "author": "Unknown"},
        {"id": "fun_18", "text": "The best time to plant a tree was 20 years ago. The second best time is now.", "author": "Chinese Proverb"},
        {"id": "fun_19", "text": "I don't need a hair stylist, my pillow gives me a new hairstyle every morning.", "author": "Unknown"},
        {"id": "fun_20", "text": "Common sense is like deodorant. The people who need it most never use it.", "author": "Unknown"}
      ]
    };

    return json.encode(sampleQuotes[category] ?? []);
  }

  void _showCreateFileDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create ${category}.json'),
        content: Text('This will create a sample ${category}.json file with 20 quotes. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createAssetFile(category);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createAssetFile(String category) {
    final content = _createSampleQuotes(category);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category}.json Content'),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllAssets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Asset File Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('This screen checks if your JSON files are properly bundled with the app.'),
                        const SizedBox(height: 8),
                        Text('Total files checked: ${_requiredAssets.length}'),
                        Text('Files found: ${_assetStatus.values.where((v) => v['exists'] == true).length}'),
                        Text('Files missing: ${_assetStatus.values.where((v) => v['exists'] == false).length}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ..._assetStatus.entries.map((entry) {
                  final category = entry.key;
                  final data = entry.value;
                  final exists = data['exists'] ?? false;
                  final quoteCount = data['quoteCount'] ?? 0;
                  final error = data['error'];
                  
                  return Card(
                    color: exists 
                        ? (quoteCount > 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1))
                        : Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                exists 
                                    ? (quoteCount > 0 ? Icons.check_circle : Icons.warning)
                                    : Icons.error,
                                color: exists 
                                    ? (quoteCount > 0 ? Colors.green : Colors.orange)
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${category}.json',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              if (exists && quoteCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$quoteCount quotes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (!exists)
                                ElevatedButton(
                                  onPressed: () => _showCreateFileDialog(category),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Create'),
                                ),
                            ],
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Error: $error',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (exists && data['content'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Preview: ${data['content']}...',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: _checkAllAssets,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Check'),
                ),
              ],
            ),
    );
  }
}
