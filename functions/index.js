const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

// Get quotes by category
exports.getQuotesByCategory = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const {categoryId} = data;

    // Validate input
    if (!categoryId) {
      throw new functions.https.HttpsError(
        "invalid-argument", 
        "Category ID is required"
      );
    }

    try {
      // Map categories to API tags
      const categoryToTagMap = {
        alone: "solitude",
        angry: "anger",
        attitude: "attitude",
        breakup: "love",
        emotional: "emotions",
        family: "family",
        friends: "friendship",
        funny: "humor",
        love: "love",
        motivational: "motivational",
        success: "success",
        wisdom: "wisdom",
      };

      const tag = categoryToTagMap[categoryId.toLowerCase()] || categoryId.toLowerCase();

      // Make request to Quotable API
      const response = await fetch(`https://api.quotable.io/quotes?tags=${tag}&limit=10`);

      if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}`);
      }

      const apiData = await response.json();

      // Transform the data to match your QuoteModel
      const quotes = apiData.results.map((quote) => ({
        id: quote._id,
        text: quote.content,
        author: quote.author,
        isFavorite: false,
      }));

      return {quotes, success: true};
    } catch (error) {
      console.error("Error fetching quotes:", error);
      throw new functions.https.HttpsError("internal", "Failed to fetch quotes");
    }
  });


// Get random quote for quote of the day - explicitly using us-central1 region
exports.getRandomQuote = functions.region("us-central1").https.onCall(async (data, context) => {
  try {
    const fetch = require("node-fetch");
    const response = await fetch("https://api.quotable.io/random");

    if (!response.ok) {
      throw new Error(`API request failed with status ${response.status}`);
    }

    const quoteData = await response.json();

    const quote = {
      id: quoteData._id,
      text: quoteData.content,
      author: quoteData.author,
      isFavorite: false,
    };

    return {quote, success: true};
  } catch (error) {
    console.error("Error fetching random quote:", error);
    throw new functions.https.HttpsError("internal", "Failed to fetch random quote");
  }
});

// Search quotes - explicitly using us-central1 region
exports.searchQuotes = functions.region("us-central1").https.onCall(async (data, context) => {
  const {query} = data;

  if (!query) {
    throw new functions.https.HttpsError("invalid-argument", "Search query is required");
  }

  try {
    const fetch = require("node-fetch");
    const response = await fetch(`https://api.quotable.io/search/quotes?query=${encodeURIComponent(query)}&limit=10`);

    if (!response.ok) {
      throw new Error(`API request failed with status ${response.status}`);
    }

    const apiData = await response.json();

    const quotes = apiData.results.map((quote) => ({
      id: quote._id,
      text: quote.content,
      author: quote.author,
      isFavorite: false,
    }));

    return {quotes, success: true};
  } catch (error) {
    console.error("Error searching quotes:", error);
    throw new functions.https.HttpsError("internal", "Failed to search quotes");
  }
});

// Save favorite quote to Firestore - explicitly using us-central1 region
exports.saveFavoriteQuote = functions.region("us-central1").https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const {quote} = data;
  const userId = context.auth.uid;

  try {
    await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("favorites")
        .doc(quote.id)
        .set({
          ...quote,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    return {success: true};
  } catch (error) {
    console.error("Error saving favorite:", error);
    throw new functions.https.HttpsError("internal", "Failed to save favorite");
  }
});

// Remove favorite quote from Firestore - explicitly using us-central1 region
exports.removeFavoriteQuote = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const {quoteId} = data;
  const userId = context.auth.uid;

  try {
    await admin.firestore().collection("users").doc(userId).collection("favorites").doc(quoteId).delete();

    return {success: true};
  } catch (error) {
    console.error("Error removing favorite:", error);
    throw new functions.https.HttpsError("internal", "Failed to remove favorite");
  }
});

// Get user's favorite quotes - explicitly using us-central1 region
exports.getFavoriteQuotes = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;

  try {
    const snapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("favorites")
        .orderBy("createdAt", "desc")
        .get();

    const favorites = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {favorites, success: true};
  } catch (error) {
    console.error("Error getting favorites:", error);
    throw new functions.https.HttpsError("internal", "Failed to get favorites");
  }
});

