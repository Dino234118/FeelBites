import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const FeelBitesApp());
}

class FeelBitesApp extends StatelessWidget {
  const FeelBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeelBites',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      debugShowCheckedModeBanner: false,
      home: const LaunchPage(),
    );
  }
}

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'FeelBites',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pinkAccent,
                ),
                child: const Text('Start Your Culinary Journey!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _emotion = "";
  List<Map<String, dynamic>> _recipes = [];

  Future<void> fetchRecipe(String userInput) async {
    final url = 'http://127.0.0.1:5001/predict';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_input": userInput}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              _emotion = data['emotion'] ?? "Unknown Emotion";
              _recipes = (data['recipes'] as Map<String, dynamic>)
                  .entries
                  .map((entry) => {
                        "name": entry.key,
                        ...entry.value as Map<String, dynamic>,
                      })
                  .toList();
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unexpected response format from the server')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server Error: ${response.statusCode}')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to the server: $error')),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('FeelBites'),
      centerTitle: true,
    ),
    body: SingleChildScrollView(  // Added SingleChildScrollView here
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'What’s your mood today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter your mood...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                fetchRecipe(_controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 255, 208, 68),
              ),
              child: const Text('Get Recipe'),
            ),
            const SizedBox(height: 20),
            if (_emotion.isNotEmpty) ...[
              Text(
                'Detected Emotion: $_emotion',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Recommended Recipes:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              for (var recipe in _recipes) ...[
                const SizedBox(height: 10),
                Text(
                  recipe['title'] ?? "Recipe Title Unavailable",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ingredients: ${recipe['ingredients']?.join(', ') ?? "Ingredients Unavailable"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Instructions: ${recipe['instructions'] ?? "Instructions Unavailable"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.white),
              ],
            ],
            const SizedBox(height: 20),
            const Divider(color: Colors.white),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton('Enhance your Mood', Icons.mood),
                _buildOptionButton('Grocery Shopping', Icons.shopping_cart),
                _buildOptionButton('Order your Food', Icons.fastfood),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildOptionButton(String text, IconData icon) {
  return Column(
    children: [
      IconButton(
        onPressed: () async {
          try {
            final encodedMood = Uri.encodeComponent(text);
            final response = await http.get(
              Uri.parse('http://localhost:5001/enhance_mood?mood=$encodedMood'),
            );

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['playlist_url'] != null) {
                final Uri url = Uri.parse(data['playlist_url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open Spotify playlist')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No playlist URL found in the response')),
                  );
                }
              }
            } else {
              final data = json.decode(response.body);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(data['error'] ?? 'Error getting playlist')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error connecting to server')),
              );
            }
          }
        },
        icon: Icon(icon, color: Colors.white, size: 30),
      ),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
}