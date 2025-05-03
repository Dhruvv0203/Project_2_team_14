// DUE TO LENGTH LIMITS, the code will be given in parts.
// Part 1: imports and main app structure

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookhubApp());
}

class BookhubApp extends StatelessWidget {
  const BookhubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookhub',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ));
    });

    return const Scaffold(
      body: Center(
        child: Text(
          '📚 Bookhub',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const DashboardPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

//_______________________________________________

// Part 2: LoginPage, RegisterPage, GenreSelectionPage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: login, child: const Text('Login')),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
            },
            child: const Text("No account? Register here"),
          )
        ]),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GenreSelectionPage(userId: userCred.user!.uid)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Password must be at least 6 characters.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: register, child: const Text('Register')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Already have an account? Login"),
          )
        ]),
      ),
    );
  }
}

class GenreSelectionPage extends StatefulWidget {
  final String userId;
  const GenreSelectionPage({super.key, required this.userId});

  @override
  State<GenreSelectionPage> createState() => _GenreSelectionPageState();
}

class _GenreSelectionPageState extends State<GenreSelectionPage> {
  final List<String> genres = [
    'Fantasy', 'Science Fiction', 'Mystery', 'Romance',
    'Non-Fiction', 'Historical', 'Thriller', 'Biography'
  ];
  final Set<String> selectedGenres = {};

  void submitGenres() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
      'genres': selectedGenres.toList()
    });
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Favorite Genres')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: genres.map((genre) {
                final selected = selectedGenres.contains(genre);
                return ListTile(
                  title: Text(genre),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        val == true ? selectedGenres.add(genre) : selectedGenres.remove(genre);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: submitGenres,
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
//____________________________________

// Part 3: DashboardPage, BookSearchPage, ReviewPage, ReadingListsPage, DiscussionBoardPage

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Bookhub Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text("Search Books"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookSearchPage())),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text("Reading Lists"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingListsPage())),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text("Write a Review"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewPage())),
          ),
          ListTile(
            leading: const Icon(Icons.forum),
            title: const Text("Discussion Board"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscussionBoardPage())),
          ),
        ],
      ),
    );
  }
}

// --- Book Search Page ---
class BookSearchPage extends StatefulWidget {
  const BookSearchPage({super.key});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final searchController = TextEditingController();
  List<dynamic> searchResults = [];
  Map<String, List<dynamic>> genreRecommendations = {};
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final genres = List<String>.from(userDoc.data()?['genres'] ?? []);

    for (final genre in genres) {
      final url = Uri.parse("https://www.googleapis.com/books/v1/volumes?q=subject:$genre");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          genreRecommendations[genre] = data['items'] ?? [];
        });
      }
    }
  }

  Future<void> searchBooks() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => searchResults = data['items'] ?? []);
    }
  }

  Widget buildBookTile(dynamic book) {
    final info = book['volumeInfo'];
    final title = info['title'] ?? 'Untitled';
    final authors = (info['authors'] ?? ['Unknown']).join(', ');
    final rating = info['averageRating']?.toString() ?? 'N/A';
    final thumbnail = info['imageLinks']?['thumbnail'];

    return ListTile(
      leading: thumbnail != null
          ? Image.network(thumbnail, width: 40, height: 60, fit: BoxFit.cover)
          : const Icon(Icons.book),
      title: Text(title),
      subtitle: Text("Author: $authors\nRating: $rating"),
    );
  }

  Widget buildGenreSection(String genre, List<dynamic> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("📚 Recommended in $genre", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Column(children: books.take(5).map(buildBookTile).toList()),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Books")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(labelText: 'Enter book title...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: searchBooks),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isSearching
                  ? ListView(children: searchResults.map(buildBookTile).toList())
                  : ListView(
                      children: genreRecommendations.entries
                          .map((entry) => buildGenreSection(entry.key, entry.value))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Reading Lists Page ---
class ReadingListsPage extends StatefulWidget {
  const ReadingListsPage({super.key});

  @override
  State<ReadingListsPage> createState() => _ReadingListsPageState();
}

class _ReadingListsPageState extends State<ReadingListsPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final tabs = ['Want to Read', 'Currently Reading', 'Finished'];

  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];

  Future<void> searchBooks(String query) async {
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        searchResults = data['items'] ?? [];
      });
    }
  }

  void showSearchDialog(String listName) {
  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> searchBooks(String query) async {
            final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query');
            final res = await http.get(url);
            if (res.statusCode == 200) {
              final data = json.decode(res.body);
              setStateDialog(() {
                searchResults = data['items'] ?? [];
              });
            }
          }

          return Dialog(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search to Add Book to "$listName"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    onChanged: searchBooks,
                    decoration: const InputDecoration(
                      labelText: "Search Books",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: searchResults.isEmpty
                        ? const Center(child: Text("No results yet."))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (_, i) {
                              final book = searchResults[i]['volumeInfo'];
                              final title = book['title'] ?? 'Untitled';
                              final authors = (book['authors'] ?? ['Unknown']).join(', ');
                              final thumbnail = book['imageLinks']?['thumbnail'] ?? '';
                              final bookId = searchResults[i]['id'];

                              return ListTile(
                                leading: thumbnail.isNotEmpty
                                    ? Image.network(thumbnail, width: 40, height: 60, fit: BoxFit.cover)
                                    : const Icon(Icons.book),
                                title: Text(title),
                                subtitle: Text(authors),
                                onTap: () async {
                                  final ref = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection(listName);

                                  await ref.add({
                                    'title': title,
                                    'authors': authors,
                                    'thumbnail': thumbnail,
                                    'googleBooksId': bookId,
                                  });

                                  searchController.clear();
                                  setState(() => searchResults.clear());  // clears outer list
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



  Widget listView(String listName) {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection(listName);

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => showSearchDialog(listName),
          icon: const Icon(Icons.add),
          label: const Text("Search & Add Book"),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ref.snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final book = docs[i];
                  return ListTile(
                    leading: (book['thumbnail'] ?? '').isNotEmpty
                        ? Image.network(book['thumbnail'], width: 40, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.book),
                    title: Text(book['title']),
                    subtitle: Text(book['authors'] ?? 'Unknown'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => book.reference.delete(),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📖 Reading Lists"),
          bottom: TabBar(tabs: tabs.map((e) => Tab(text: e)).toList()),
        ),
        body: TabBarView(children: tabs.map(listView).toList()),
      ),
    );
  }
}


// ______________________________________________________

// --- Review Page ---
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final username = FirebaseAuth.instance.currentUser!.email ?? "Anonymous";

  final searchController = TextEditingController();
  final reviewController = TextEditingController();
  double rating = 3.0;
  List<dynamic> searchResults = [];
  Map<String, dynamic>? selectedBook;

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => searchResults = data['items'] ?? []);
    }
  }

  Future<void> submitReview() async {
    if (selectedBook == null) return;

    if (reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ You must write something about the book")),
      );
      return;
    }

    final volume = selectedBook!['volumeInfo'];
    final bookId = selectedBook!['id'];
    final title = volume['title'] ?? "Untitled";
    final authors = (volume['authors'] ?? ['Unknown']).join(', ');
    final thumbnail = volume['imageLinks']?['thumbnail'] ?? '';

    await FirebaseFirestore.instance.collection('reviews').add({
      'uid': uid,
      'username': username,
      'bookId': bookId,
      'title': title,
      'authors': authors,
      'thumbnail': thumbnail,
      'review': reviewController.text.trim(),
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      selectedBook = null;
      searchController.clear();
      reviewController.clear();
      rating = 3.0;
      searchResults.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Review submitted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("✍️ Write a Review")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(labelText: 'Search for a Book'),
              onChanged: searchBooks,
            ),
            const SizedBox(height: 10),
            if (searchResults.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                itemBuilder: (_, i) {
                  final book = searchResults[i]['volumeInfo'];
                  final title = book['title'] ?? 'Untitled';
                  final authors = (book['authors'] ?? ['Unknown']).join(', ');
                  final thumbnail = book['imageLinks']?['thumbnail'] ?? '';

                  return ListTile(
                    leading: thumbnail.isNotEmpty
                        ? Image.network(thumbnail, width: 40, height: 60)
                        : const Icon(Icons.book),
                    title: Text(title),
                    subtitle: Text(authors),
                    onTap: () {
                      setState(() {
                        selectedBook = searchResults[i];
                        searchResults.clear();
                        searchController.text = title;
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 10),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(labelText: 'Your Review'),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Rating: "),
                Expanded(
                  child: Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: rating.toStringAsFixed(1),
                    onChanged: (val) => setState(() => rating = val),
                  ),
                ),
              ],
            ),
            ElevatedButton(onPressed: submitReview, child: const Text("Submit Review")),
            const Divider(height: 40),
            const Text("📝 All Reviews", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final reviews = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (_, i) {
                    final review = reviews[i];
                    final data = review.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: (data['thumbnail'] ?? '').toString().isNotEmpty
                          ? Image.network(data['thumbnail'], width: 40, height: 60)
                          : const Icon(Icons.book),
                      title: Text("${data['title']} - (${data['rating'].toStringAsFixed(1)}/5)"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['review']),
                          Text("- ${data['username']}"),
                        ],
                      ),
                    );
                  }

                );
              },
            )
          ]),
        ),
      ),
    );
  }
}



// --- Discussion Board Page ---
class DiscussionBoardPage extends StatefulWidget {
  const DiscussionBoardPage({super.key});

  @override
  State<DiscussionBoardPage> createState() => _DiscussionBoardPageState();
}

class _DiscussionBoardPageState extends State<DiscussionBoardPage> {
  final messageController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final username = FirebaseAuth.instance.currentUser!.email ?? "Anonymous";
  final messagesRef = FirebaseFirestore.instance.collection('discussion').orderBy('timestamp', descending: true);

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance.collection('discussion').add({
      'uid': uid,
      'username': username,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💬 Discussion Board")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg['uid'] == uid;
                    return ListTile(
                      title: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.indigo[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(msg['text']),
                        ),
                      ),
                      subtitle: isMe ? null : Text(msg['username']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(hintText: "Enter message..."),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
