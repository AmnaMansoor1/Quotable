import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quote_model.dart';
import 'local_favorites_service.dart';
import 'favorites_service.dart';

class QuoteService {
  // Using ZenQuotes API - no CORS restrictions
  static const String baseUrl = 'https://zenquotes.io/api';
  
  // Initialize favorites service
  final LocalFavoritesService _localFavoritesService = LocalFavoritesService();
  final FavoritesService _favoritesService = FavoritesService();
  
  // Cache for quotes to improve performance
  static final Map<String, List<QuoteModel>> _quotesCache = {};
  static final Map<String, List<QuoteModel>> _apiQuotesCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  // Category-specific quotes that actually match the categories
  static final Map<String, List<Map<String, String>>> _categoryQuotes = {
    'alone': [
      {"text": "The greatest thing in the world is to know how to belong to oneself.", "author": "Michel de Montaigne"},
      {"text": "I think it's very healthy to spend time alone. You need to know how to be alone and not be defined by another person.", "author": "Olivia Wilde"},
      {"text": "The best part about being alone is that you really don't have to answer to anybody.", "author": "Justin Timberlake"},
      {"text": "I never found a companion that was so companionable as solitude.", "author": "Henry David Thoreau"},
      {"text": "Being alone has a power that very few people can handle.", "author": "Steven Aitchison"},
      {"text": "Loneliness is not lack of company, loneliness is lack of purpose.", "author": "Guillermo Maldonado"},
      {"text": "The time you feel lonely is the time you most need to be by yourself.", "author": "Douglas Coupland"},
      {"text": "Sometimes you need to sit lonely on the floor in a quiet room in order to hear your own voice and not let it drown in the noise of others.", "author": "Charlotte Eriksson"},
      {"text": "Learn to be alone and to like it. There is nothing more freeing and empowering than learning to like your own company.", "author": "Mandy Hale"},
      {"text": "The soul that sees beauty may sometimes walk alone.", "author": "Johann Wolfgang von Goethe"},
      {"text": "I restore myself when I'm alone.", "author": "Marilyn Monroe"},
      {"text": "Solitude is where I place my chaos to rest and awaken my inner peace.", "author": "Nikki Rowe"},
      {"text": "Being alone never felt right. Sometimes it felt good, but it never felt right.", "author": "Charles Bukowski"},
      {"text": "The capacity to be alone is the capacity to love.", "author": "Osho"},
      {"text": "I love to be alone. I never found the companion that was so companionable as solitude.", "author": "Henry David Thoreau"},
      {"text": "Sometimes you have to stand alone to prove that you can still stand.", "author": "Unknown"},
      {"text": "Alone time is when I distance myself from the voices of the world so I can hear my own.", "author": "Oprah Winfrey"},
      {"text": "The person who tries to live alone will not succeed as a human being.", "author": "Pearl S. Buck"},
      {"text": "We're born alone, we live alone, we die alone. Only through our love and friendship can we create the illusion for the moment that we're not alone.", "author": "Hunter S. Thompson"},
      {"text": "All cruelty springs from weakness.", "author": "Seneca"}
    ],
    'angry': [
      {"text": "Anger is an acid that can do more harm to the vessel in which it is stored than to anything on which it is poured.", "author": "Mark Twain"},
      {"text": "For every minute you remain angry, you give up sixty seconds of peace of mind.", "author": "Ralph Waldo Emerson"},
      {"text": "Holding on to anger is like grasping a hot coal with the intent of throwing it at someone else; you are the one who gets burned.", "author": "Buddha"},
      {"text": "Anger makes you smaller, while forgiveness forces you to grow beyond what you are.", "author": "Cherie Carter-Scott"},
      {"text": "The best fighter is never angry.", "author": "Lao Tzu"},
      {"text": "Speak when you are angry and you will make the best speech you will ever regret.", "author": "Ambrose Bierce"},
      {"text": "Anger is a wind which blows out the lamp of the mind.", "author": "Robert Green Ingersoll"},
      {"text": "When anger rises, think of the consequences.", "author": "Confucius"},
      {"text": "Anger dwells only in the bosom of fools.", "author": "Albert Einstein"},
      {"text": "Don't hold to anger, hurt or pain. They steal your energy and keep you from love.", "author": "Leo Buscaglia"},
      {"text": "Anger is never without a reason, but seldom with a good one.", "author": "Benjamin Franklin"},
      {"text": "The greatest remedy for anger is delay.", "author": "Thomas Paine"},
      {"text": "Anger is one letter short of danger.", "author": "Eleanor Roosevelt"},
      {"text": "How much more grievous are the consequences of anger than the causes of it.", "author": "Marcus Aurelius"},
      {"text": "Anger is a killing thing: it kills the man who angers, for each rage leaves him less than he had been before.", "author": "Louis L'Amour"},
      {"text": "Never go to bed mad. Stay up and fight.", "author": "Phyllis Diller"},
      {"text": "Anger is the enemy of non-violence and pride is a monster that swallows it up.", "author": "Mahatma Gandhi"},
      {"text": "Anger and intolerance are the enemies of correct understanding.", "author": "Mahatma Gandhi"},
      {"text": "Where there is anger, there is always pain underneath.", "author": "Eckhart Tolle"},
      {"text": "Anger is a momentary madness, so control your passion or it will control you.", "author": "G. M. Trevelyan"}
    ],
    'attitude': [
      {"text": "Your attitude, not your aptitude, will determine your altitude.", "author": "Zig Ziglar"},
      {"text": "Attitude is a little thing that makes a big difference.", "author": "Winston Churchill"},
      {"text": "A positive attitude causes a chain reaction of positive thoughts, events and outcomes.", "author": "Wade Boggs"},
      {"text": "The only disability in life is a bad attitude.", "author": "Scott Hamilton"},
      {"text": "Excellence is not a skill, it's an attitude.", "author": "Ralph Marston"},
      {"text": "Your attitude determines your direction.", "author": "Unknown"},
      {"text": "Attitude is everything, so pick a good one.", "author": "Wayne Dyer"},
      {"text": "A bad attitude is like a flat tire. You can't go anywhere until you change it.", "author": "Unknown"},
      {"text": "The greatest discovery of all time is that a person can change his future by merely changing his attitude.", "author": "Oprah Winfrey"},
      {"text": "Life is 10% what happens to you and 90% how you react to it.", "author": "Charles R. Swindoll"},
      {"text": "Positive anything is better than negative nothing.", "author": "Elbert Hubbard"},
      {"text": "Keep your face always toward the sunshine—and shadows will fall behind you.", "author": "Walt Whitman"},
      {"text": "A strong positive attitude will create more miracles than any wonder drug.", "author": "Patricia Neal"},
      {"text": "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.", "author": "Winston Churchill"},
      {"text": "Attitude is a choice. Happiness is a choice. Optimism is a choice.", "author": "Shawn Achor"},
      {"text": "You cannot control what happens to you, but you can control your attitude toward what happens to you.", "author": "Brian Tracy"},
      {"text": "A positive attitude can really make dreams come true - it did for me.", "author": "David Bailey"},
      {"text": "The only thing you can control is your attitude. Control it.", "author": "Unknown"},
      {"text": "Weakness of attitude becomes weakness of character.", "author": "Albert Einstein"},
      {"text": "If you don't like something, change it. If you can't change it, change your attitude.", "author": "Maya Angelou"}
    ],
    'breakup': [
      {"text": "Sometimes good things fall apart so better things can fall together.", "author": "Marilyn Monroe"},
      {"text": "The hottest love has the coldest end.", "author": "Socrates"},
      {"text": "Don't cry because it's over, smile because it happened.", "author": "Dr. Seuss"},
      {"text": "The heart was made to be broken.", "author": "Oscar Wilde"},
      {"text": "Pain makes you stronger, fear makes you braver, heartbreak makes you wiser.", "author": "Unknown"},
      {"text": "Every heart that has beat strongly and cheerfully has left a hopeful impulse behind it in the world.", "author": "Robert Louis Stevenson"},
      {"text": "The cure for anything is salt water: sweat, tears or the sea.", "author": "Isak Dinesen"},
      {"text": "You can love someone so much...But you can never love people as much as you can miss them.", "author": "John Green"},
      {"text": "It is better to have loved and lost than never to have loved at all.", "author": "Alfred Lord Tennyson"},
      {"text": "Hearts will never be practical until they are made unbreakable.", "author": "L. Frank Baum"},
      {"text": "The emotion that can break your heart is sometimes the very one that heals it.", "author": "Nicholas Sparks"},
      {"text": "Sometimes you have to forget what you feel, and remember what you deserve.", "author": "Unknown"},
      {"text": "The only way to fix a broken heart is to give God all the pieces.", "author": "Unknown"},
      {"text": "Letting go doesn't mean that you don't care about someone anymore. It's just realizing that the only person you really have control over is yourself.", "author": "Deborah Reber"},
      {"text": "You were my cup of tea, but I drink coffee now.", "author": "Unknown"},
      {"text": "Sometimes you have to give up on people. Not because you don't care, but because they don't.", "author": "Unknown"},
      {"text": "The worst kind of pain is when you're smiling just to stop the tears from falling.", "author": "Unknown"},
      {"text": "Moving on doesn't mean you forget about things. It just means you have to accept what's happened and continue living.", "author": "Unknown"},
      {"text": "Don't let someone who gave up on you make you give up on yourself.", "author": "Unknown"},
      {"text": "Sometimes the only way to let go is to love someone enough to want the best for him or her even if that means not being together.", "author": "Unknown"}
    ],
    'emotional': [
      {"text": "The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.", "author": "Helen Keller"},
      {"text": "Tears are words that need to be written.", "author": "Paulo Coelho"},
      {"text": "The emotion that can break your heart is sometimes the very one that heals it.", "author": "Nicholas Sparks"},
      {"text": "We are all broken, that's how the light gets in.", "author": "Ernest Hemingway"},
      {"text": "The deeper that sorrow carves into your being, the more joy you can contain.", "author": "Kahlil Gibran"},
      {"text": "Your emotions are the slaves to your thoughts, and you are the slave to your emotions.", "author": "Elizabeth Gilbert"},
      {"text": "The only way out is through.", "author": "Robert Frost"},
      {"text": "Feelings are much like waves, we can't stop them from coming but we can choose which one to surf.", "author": "Jonatan Mårtensson"},
      {"text": "The cave you fear to enter holds the treasure you seek.", "author": "Joseph Campbell"},
      {"text": "What we feel most has no name but amber, archers, cinnamon, horses and birds.", "author": "Jack Gilbert"},
      {"text": "The wound is the place where the Light enters you.", "author": "Rumi"},
      {"text": "Heavy hearts, like heavy clouds in the sky, are best relieved by the letting of a little water.", "author": "Christopher Morley"},
      {"text": "Sometimes you need to sit lonely on the floor in a quiet room in order to hear your own voice.", "author": "Charlotte Eriksson"},
      {"text": "The most beautiful people are those who have known defeat, known suffering, known struggle, known loss.", "author": "Elisabeth Kübler-Ross"},
      {"text": "Your pain is the breaking of the shell that encloses your understanding.", "author": "Kahlil Gibran"},
      {"text": "Embrace your emotions. They are information.", "author": "Unknown"},
      {"text": "The privilege of a lifetime is being who you are.", "author": "Joseph Campbell"},
      {"text": "What lies behind us and what lies before us are tiny matters compared to what lies within us.", "author": "Ralph Waldo Emerson"},
      {"text": "Turn your wounds into wisdom.", "author": "Oprah Winfrey"},
      {"text": "The heart has its reasons which reason knows not.", "author": "Blaise Pascal"}
    ],
    'family': [
      {"text": "Family is not an important thing. It's everything.", "author": "Michael J. Fox"},
      {"text": "The love of a family is life's greatest blessing.", "author": "Unknown"},
      {"text": "Family means no one gets left behind or forgotten.", "author": "David Ogden Stiers"},
      {"text": "In family life, love is the oil that eases friction, the cement that binds closer together.", "author": "Friedrich Nietzsche"},
      {"text": "A happy family is but an earlier heaven.", "author": "George Bernard Shaw"},
      {"text": "Family is where life begins and love never ends.", "author": "Unknown"},
      {"text": "The memories we make with our family is everything.", "author": "Candace Cameron Bure"},
      {"text": "Family is the most important thing in the world.", "author": "Princess Diana"},
      {"text": "Being a family means you are a part of something very wonderful.", "author": "Unknown"},
      {"text": "Family isn't always blood. It's the people in your life who want you in theirs.", "author": "Unknown"},
      {"text": "The family is one of nature's masterpieces.", "author": "George Santayana"},
      {"text": "Home is where your family is.", "author": "Unknown"},
      {"text": "Family is the anchor that holds us through life's storms.", "author": "Unknown"},
      {"text": "A family's love is like a circle. It has no beginning and no ending.", "author": "Unknown"},
      {"text": "The most important thing in the world is family and love.", "author": "John Wooden"},
      {"text": "Family is not about blood. It's about who is willing to hold your hand when you need it the most.", "author": "Unknown"},
      {"text": "Family time is sacred time and should be protected and respected.", "author": "Boyd K. Packer"},
      {"text": "The bond that links your true family is not one of blood, but of respect and joy in each other's life.", "author": "Richard Bach"},
      {"text": "Family is the heart of a home.", "author": "Unknown"},
      {"text": "In every conceivable manner, the family is link to our past, bridge to our future.", "author": "Alex Haley"}
    ],
    'friends': [
      {"text": "A friend is someone who knows all about you and still loves you.", "author": "Elbert Hubbard"},
      {"text": "Friendship is born at that moment when one person says to another, 'What! You too? I thought I was the only one.'", "author": "C.S. Lewis"},
      {"text": "A true friend is one who overlooks your failures and tolerates your success.", "author": "Doug Larson"},
      {"text": "A good friend is like a four-leaf clover; hard to find and lucky to have.", "author": "Irish Proverb"},
      {"text": "There is nothing I would not do for those who are really my friends.", "author": "Jane Austen"},
      {"text": "True friendship comes when the silence between two people is comfortable.", "author": "David Tyson"},
      {"text": "Friends are the siblings God never gave us.", "author": "Mencius"},
      {"text": "A friend is what the heart needs all the time.", "author": "Henry Van Dyke"},
      {"text": "Friendship is the only cement that will ever hold the world together.", "author": "Woodrow Wilson"},
      {"text": "A true friend is someone who thinks that you are a good egg even though he knows that you are slightly cracked.", "author": "Bernard Meltzer"},
      {"text": "Friends show their love in times of trouble, not in happiness.", "author": "Euripides"},
      {"text": "Friendship is not about who you've known the longest. It's about who walked into your life and said 'I'm here for you' and proved it.", "author": "Unknown"},
      {"text": "The greatest gift of life is friendship, and I have received it.", "author": "Hubert H. Humphrey"},
      {"text": "A friend is someone who gives you total freedom to be yourself.", "author": "Jim Morrison"},
      {"text": "Friends are those rare people who ask how we are and then wait to hear the answer.", "author": "Ed Cunningham"},
      {"text": "A single rose can be my garden... a single friend, my world.", "author": "Leo Buscaglia"},
      {"text": "Friendship marks a life even more deeply than love.", "author": "Elie Wiesel"},
      {"text": "The most beautiful discovery true friends make is that they can grow separately without growing apart.", "author": "Elisabeth Foley"},
      {"text": "In the cookie of life, friends are the chocolate chips.", "author": "Salman Rushdie"},
      {"text": "A friend is one that knows you as you are, understands where you have been, accepts what you have become, and still, gently allows you to grow.", "author": "William Shakespeare"}
    ],
    'funny': [
      {"text": "I'm not superstitious, but I am a little stitious.", "author": "Michael Scott"},
      {"text": "The trouble with having an open mind, of course, is that people will insist on coming along and trying to put things in it.", "author": "Terry Pratchett"},
      {"text": "I haven't slept for ten days, because that would be too long.", "author": "Mitch Hedberg"},
      {"text": "I used to think I was indecisive, but now I'm not so sure.", "author": "Unknown"},
      {"text": "The early bird might get the worm, but the second mouse gets the cheese.", "author": "Willie Nelson"},
      {"text": "I told my wife the truth. I told her I was seeing a psychiatrist. Then she told me the truth: that she was seeing a psychiatrist, two plumbers, and a bartender.", "author": "Rodney Dangerfield"},
      {"text": "Behind every great man is a woman rolling her eyes.", "author": "Jim Carrey"},
      {"text": "Do not take life too seriously. You will never get out of it alive.", "author": "Elbert Hubbard"},
      {"text": "Everyone should be able to do one card trick, tell two jokes, and recite three poems, in case they are ever trapped in an elevator.", "author": "Lemony Snicket"},
      {"text": "The difference between stupidity and genius is that genius has its limits.", "author": "Albert Einstein"},
      {"text": "If you think you are too small to make a difference, try sleeping with a mosquito.", "author": "Dalai Lama"},
      {"text": "A day without sunshine is like, you know, night.", "author": "Steve Martin"},
      {"text": "The road to success is dotted with many tempting parking spaces.", "author": "Will Rogers"},
      {"text": "I'm writing a book. I've got the page numbers done.", "author": "Steven Wright"},
      {"text": "If at first you don't succeed, then skydiving definitely isn't for you.", "author": "Steven Wright"},
      {"text": "Money talks...but all mine ever says is good-bye.", "author": "Unknown"},
      {"text": "I'm not arguing, I'm just explaining why I'm right.", "author": "Unknown"},
      {"text": "The best time to plant a tree was 20 years ago. The second best time is now.", "author": "Chinese Proverb"},
      {"text": "I don't need a hair stylist, my pillow gives me a new hairstyle every morning.", "author": "Unknown"},
      {"text": "Common sense is like deodorant. The people who need it most never use it.", "author": "Unknown"}
    ],
    'love': [
      {"text": "Being deeply loved by someone gives you strength, while loving someone deeply gives you courage.", "author": "Lao Tzu"},
      {"text": "The best thing to hold onto in life is each other.", "author": "Audrey Hepburn"},
      {"text": "Love is composed of a single soul inhabiting two bodies.", "author": "Aristotle"},
      {"text": "Where there is love there is life.", "author": "Mahatma Gandhi"},
      {"text": "You know you're in love when you can't fall asleep because reality is finally better than your dreams.", "author": "Dr. Seuss"},
      {"text": "Love is not about how many days, months, or years you have been together. Love is about how much you love each other every single day.", "author": "Unknown"},
      {"text": "The greatest happiness of life is the conviction that we are loved; loved for ourselves, or rather, loved in spite of ourselves.", "author": "Victor Hugo"},
      {"text": "Love recognizes no barriers. It jumps hurdles, leaps fences, penetrates walls to arrive at its destination full of hope.", "author": "Maya Angelou"},
      {"text": "To love and be loved is to feel the sun from both sides.", "author": "David Viscott"},
      {"text": "Love is when the other person's happiness is more important than your own.", "author": "H. Jackson Brown Jr."},
      {"text": "The best love is the kind that awakens the soul and makes us reach for more.", "author": "Nicholas Sparks"},
      {"text": "Love is friendship that has caught fire.", "author": "Ann Landers"},
      {"text": "In all the world, there is no heart for me like yours. In all the world, there is no love for you like mine.", "author": "Maya Angelou"},
      {"text": "Love doesn't make the world go 'round. Love is what makes the ride worthwhile.", "author": "Franklin P. Jones"},
      {"text": "The real lover is the man who can thrill you by kissing your forehead or smiling into your eyes or just staring into space.", "author": "Marilyn Monroe"},
      {"text": "Love is not finding someone to live with. It's finding someone you can't live without.", "author": "Rafael Ortiz"},
      {"text": "A successful marriage requires falling in love many times, always with the same person.", "author": "Mignon McLaughlin"},
      {"text": "Love is the bridge between you and everything.", "author": "Rumi"},
      {"text": "The heart wants what it wants. There's no logic to these things. You meet someone and you fall in love and that's that.", "author": "Woody Allen"},
      {"text": "Love is a canvas furnished by nature and embroidered by imagination.", "author": "Voltaire"}
    ],
    'motivational': [
      {"text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
      {"text": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"},
      {"text": "Your time is limited, don't waste it living someone else's life.", "author": "Steve Jobs"},
      {"text": "Stay hungry, stay foolish.", "author": "Steve Jobs"},
      {"text": "The future belongs to those who believe in the beauty of their dreams.", "author": "Eleanor Roosevelt"},
      {"text": "It is during our darkest moments that we must focus to see the light.", "author": "Aristotle"},
      {"text": "Success is not final, failure is not fatal: it is the courage to continue that counts.", "author": "Winston Churchill"},
      {"text": "The way to get started is to quit talking and begin doing.", "author": "Walt Disney"},
      {"text": "Don't let yesterday take up too much of today.", "author": "Will Rogers"},
      {"text": "You learn more from failure than from success.", "author": "Unknown"},
      {"text": "If you are working on something exciting that you really care about, you don't have to be pushed.", "author": "Steve Jobs"},
      {"text": "Don't be afraid to give up the good to go for the great.", "author": "John D. Rockefeller"},
      {"text": "The only impossible journey is the one you never begin.", "author": "Tony Robbins"},
      {"text": "In the middle of difficulty lies opportunity.", "author": "Albert Einstein"},
      {"text": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
      {"text": "The only person you are destined to become is the person you decide to be.", "author": "Ralph Waldo Emerson"},
      {"text": "Go confidently in the direction of your dreams.", "author": "Henry David Thoreau"},
      {"text": "When you have a dream, you've got to grab it and never let go.", "author": "Carol Burnett"},
      {"text": "Nothing is impossible. The word itself says 'I'm possible!'", "author": "Audrey Hepburn"},
      {"text": "There is nothing impossible to they who will try.", "author": "Alexander the Great"}
    ],
    'success': [
      {"text": "Success is not the key to happiness. Happiness is the key to success.", "author": "Albert Schweitzer"},
      {"text": "Don't be afraid to give up the good to go for the great.", "author": "John D. Rockefeller"},
      {"text": "The way to get started is to quit talking and begin doing.", "author": "Walt Disney"},
      {"text": "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.", "author": "Winston Churchill"},
      {"text": "Don't let yesterday take up too much of today.", "author": "Will Rogers"},
      {"text": "You learn more from failure than from success. Don't let it stop you. Failure builds character.", "author": "Unknown"},
      {"text": "It's not whether you get knocked down, it's whether you get up.", "author": "Vince Lombardi"},
      {"text": "If you are working on something that you really care about, you don't have to be pushed.", "author": "Steve Jobs"},
      {"text": "Entrepreneurs are great at dealing with uncertainty and also very good at minimizing risk.", "author": "Mohnish Pabrai"},
      {"text": "We generate fears while we sit. We overcome them by action.", "author": "Dr. Henry Link"},
      {"text": "Whether you think you can or think you can't, you're right.", "author": "Henry Ford"},
      {"text": "The only impossible journey is the one you never begin.", "author": "Tony Robbins"},
      {"text": "In the middle of difficulty lies opportunity.", "author": "Albert Einstein"},
      {"text": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
      {"text": "Act as if what you do makes a difference. It does.", "author": "William James"},
      {"text": "Success is walking from failure to failure with no loss of enthusiasm.", "author": "Winston Churchill"},
      {"text": "The only person you are destined to become is the person you decide to be.", "author": "Ralph Waldo Emerson"},
      {"text": "Go confidently in the direction of your dreams.", "author": "Henry David Thoreau"},
      {"text": "When you have a dream, you've got to grab it and never let go.", "author": "Carol Burnett"},
      {"text": "Success is not in what you have, but who you are.", "author": "Bo Bennett"}
    ],
    'wisdom': [
      {"text": "The only true wisdom is in knowing you know nothing.", "author": "Socrates"},
      {"text": "The fool doth think he is wise, but the wise man knows himself to be a fool.", "author": "William Shakespeare"},
      {"text": "Yesterday is history, tomorrow is a mystery, today is a gift of God, which is why we call it the present.", "author": "Bill Keane"},
      {"text": "A wise man can learn more from a foolish question than a fool can learn from a wise answer.", "author": "Bruce Lee"},
      {"text": "The journey of a thousand miles begins with one step.", "author": "Lao Tzu"},
      {"text": "That which does not kill us makes us stronger.", "author": "Friedrich Nietzsche"},
      {"text": "Life is what happens to you while you're busy making other plans.", "author": "John Lennon"},
      {"text": "When the going gets tough, the tough get going.", "author": "Joe Kennedy"},
      {"text": "You must be the change you wish to see in the world.", "author": "Mahatma Gandhi"},
      {"text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
      {"text": "Life is really simple, but we insist on making it complicated.", "author": "Confucius"},
      {"text": "The unexamined life is not worth living.", "author": "Socrates"},
      {"text": "Turn your wounds into wisdom.", "author": "Oprah Winfrey"},
      {"text": "The way I see it, if you want the rainbow, you gotta put up with the rain.", "author": "Dolly Parton"},
      {"text": "Do not go where the path may lead, go instead where there is no path and leave a trail.", "author": "Ralph Waldo Emerson"},
      {"text": "In three words I can sum up everything I've learned about life: it goes on.", "author": "Robert Frost"},
      {"text": "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", "author": "Ralph Waldo Emerson"},
      {"text": "Here's to the crazy ones. The misfits. The rebels.", "author": "Steve Jobs"},
      {"text": "Be yourself; everyone else is already taken.", "author": "Oscar Wilde"},
      {"text": "Two things are infinite: the universe and human stupidity; and I'm not sure about the universe.", "author": "Albert Einstein"}
    ]
  };

  // Get quotes by category - HYBRID SYSTEM: Category quotes + API quotes + Premium API quotes
  Future<List<QuoteModel>> getQuotesByCategory(String categoryId) async {
    print('📚 Fetching quotes for category: $categoryId');
    
    // Check cache first
    if (_quotesCache.containsKey(categoryId) && _cacheTimestamps.containsKey(categoryId)) {
      final cacheTime = _cacheTimestamps[categoryId]!;
      if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
        print('💾 Using cached quotes for $categoryId');
        final cachedQuotes = _quotesCache[categoryId]!;
        // Update favorite status for cached quotes
        for (var quote in cachedQuotes) {
          quote.isFavorite = await _localFavoritesService.isQuoteFavorited(quote.id);
        }
        return cachedQuotes;
      }
    }
    
    // 1. Start with category-specific quotes (PRIMARY)
    print('📝 Loading category-specific quotes for $categoryId');
    final categoryQuotes = _getCategoryQuotes(categoryId);
    final allQuotes = <QuoteModel>[...categoryQuotes];
    
    // 2. Add API quotes as secondary (if available)
    print('🌐 Trying to add API quotes for $categoryId');
    try {
      final apiQuotes = await _fetchApiQuotes(categoryId);
      if (apiQuotes.isNotEmpty) {
        print('✅ Adding ${apiQuotes.length} API quotes to $categoryId');
        allQuotes.addAll(apiQuotes);
      }
    } catch (e) {
      print('⚠️ API quotes failed, continuing with category quotes: $e');
    }
    
    // 3. Add premium API quotes if unlocked
    final premiumQuotes = await _getPremiumApiQuotes(categoryId);
    if (premiumQuotes.isNotEmpty) {
      print('💎 Adding ${premiumQuotes.length} premium API quotes to $categoryId');
      allQuotes.addAll(premiumQuotes);
    }
    
    // Cache the combined quotes
    _quotesCache[categoryId] = allQuotes;
    _cacheTimestamps[categoryId] = DateTime.now();
    
    // Update favorite status for all quotes
    for (var quote in allQuotes) {
      quote.isFavorite = await _localFavoritesService.isQuoteFavorited(quote.id);
    }
    
    print('✅ Total quotes loaded for $categoryId: ${allQuotes.length} (${categoryQuotes.length} category + ${allQuotes.length - categoryQuotes.length} API/Premium)');
    return allQuotes;
  }

  // Get category-specific quotes
  List<QuoteModel> _getCategoryQuotes(String categoryId) {
    final quotesData = _categoryQuotes[categoryId] ?? _categoryQuotes['motivational']!;
    
    return quotesData.asMap().entries.map((entry) {
      final index = entry.key;
      final quoteData = entry.value;
      
      return QuoteModel(
        id: 'category_${categoryId}_$index',
        text: quoteData['text']!,
        author: quoteData['author']!,
        isFavorite: false,
      );
    }).toList();
  }

  // Fetch API quotes as secondary source
  Future<List<QuoteModel>> _fetchApiQuotes(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quotes'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final quotes = data.take(10).map((quoteData) { // Limit to 10 API quotes
          return QuoteModel(
            id: 'api_${categoryId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
            text: quoteData['q'] ?? quoteData['text'] ?? '',
            author: quoteData['a'] ?? quoteData['author'] ?? 'Unknown',
            isFavorite: false,
          );
        }).where((quote) => quote.text.isNotEmpty && quote.text.length > 10).toList();
        
        print('✅ API returned ${quotes.length} valid quotes');
        return quotes;
      } else {
        print('❌ API returned status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ API error: $e');
      return [];
    }
  }

  // Get premium API quotes (unlocked through rewards)
  Future<List<QuoteModel>> _getPremiumApiQuotes(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final premiumQuotesUnlocked = prefs.getInt('premium_quotes_unlocked') ?? 0;
    
    if (premiumQuotesUnlocked <= 0) {
      print('💎 No premium quotes unlocked for $categoryId');
      return [];
    }
    
    // Check if we have cached premium quotes for this category
    final cacheKey = 'premium_$categoryId';
    if (_apiQuotesCache.containsKey(cacheKey)) {
      final cachedPremiumQuotes = _apiQuotesCache[cacheKey]!;
      print('💾 Using cached premium quotes for $categoryId: ${cachedPremiumQuotes.length}');
      return cachedPremiumQuotes.take(premiumQuotesUnlocked).toList();
    }
    
    // Fetch fresh premium quotes from API
    try {
      print('💎 Fetching premium API quotes for $categoryId (unlocked: $premiumQuotesUnlocked)');
      
      final response = await http.get(
        Uri.parse('$baseUrl/quotes'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuoteableApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final premiumQuotes = data.skip(10).take(20).map((quoteData) { // Different set for premium
          return QuoteModel(
            id: 'premium_${categoryId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
            text: '💎 ${quoteData['q'] ?? quoteData['text'] ?? ''}', // Add premium indicator
            author: quoteData['a'] ?? quoteData['author'] ?? 'Unknown',
            isFavorite: false,
          );
        }).where((quote) => quote.text.isNotEmpty && quote.text.length > 15).toList();
        
        // Cache premium quotes
        _apiQuotesCache[cacheKey] = premiumQuotes;
        
        // Return only the number of unlocked quotes
        final quotesToReturn = premiumQuotes.take(premiumQuotesUnlocked).toList();
        print('💎 Premium API returned ${quotesToReturn.length} quotes for $categoryId');
        return quotesToReturn;
      } else {
        print('❌ Premium API returned status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Premium API error: $e');
      return [];
    }
  }

  // Unlock premium quotes (called from premium features)
  Future<void> unlockPremiumQuotes(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUnlocked = prefs.getInt('premium_quotes_unlocked') ?? 0;
    final newTotal = currentUnlocked + count;
    
    await prefs.setInt('premium_quotes_unlocked', newTotal);
    
    // Clear cache to force reload with new premium quotes
    _quotesCache.clear();
    _apiQuotesCache.clear();
    _cacheTimestamps.clear();
    
    print('💎 Unlocked $count premium quotes. Total: $newTotal');
  }

  // Get premium quotes count
  Future<int> getPremiumQuotesCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('premium_quotes_unlocked') ?? 0;
  }

  // Get random quote from random category
  Future<QuoteModel> getRandomQuote() async {
    final allCategories = _categoryQuotes.keys.toList();
    final randomCategory = allCategories[Random().nextInt(allCategories.length)];
    final quotes = await getQuotesByCategory(randomCategory); // This will include API and premium quotes
    final quote = quotes[Random().nextInt(quotes.length)];
    
    quote.isFavorite = await _localFavoritesService.isQuoteFavorited(quote.id);
    return quote;
  }

  // Search quotes across all categories
  Future<List<QuoteModel>> searchQuotes(String query) async {
    print('🔍 Searching quotes for: $query');
    
    final allQuotes = <QuoteModel>[];
    
    // Search through all categories (including API and premium quotes)
    for (String category in _categoryQuotes.keys) {
      final categoryQuotes = await getQuotesByCategory(category);
      allQuotes.addAll(categoryQuotes);
    }
    
    final lowercaseQuery = query.toLowerCase();
    final searchResults = allQuotes.where((quote) => 
      quote.text.toLowerCase().contains(lowercaseQuery) || 
      quote.author.toLowerCase().contains(lowercaseQuery)
    ).toList();

    // Update favorite status for search results
    for (var quote in searchResults) {
      quote.isFavorite = await _localFavoritesService.isQuoteFavorited(quote.id);
    }

    print('🔍 Found ${searchResults.length} search results');
    return searchResults;
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(QuoteModel quote) async {
    print('🔄 QuoteService.toggleFavorite called for: ${quote.id}');
    
    if (quote.isFavorite) {
      print('❤️ Removing from favorites via FavoritesService...');
      final success = await _favoritesService.removeFavoriteQuote(quote.id);
      if (success) {
        quote.isFavorite = false;
        print('✅ Successfully removed from favorites');
      }
      return success;
    } else {
      print('❤️ Adding to favorites via FavoritesService...');
      final success = await _favoritesService.saveFavoriteQuote(quote);
      if (success) {
        quote.isFavorite = true;
        print('✅ Successfully added to favorites');
      }
      return success;
    }
  }

  // Get favorite quotes
  Future<List<QuoteModel>> getFavoriteQuotes() async {
    print('📖 Getting favorites via FavoritesService...');
    return await _favoritesService.getFavoriteQuotes();
  }

  // Clear cache
  static void clearCache() {
    _quotesCache.clear();
    _apiQuotesCache.clear();
    _cacheTimestamps.clear();
    print('🗑️ Quote cache cleared');
  }
}
