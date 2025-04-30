import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  final String recipeName;
  final String imageUrl;
  final String calories;

  const RecipePage({
    super.key,
    required this.recipeName,
    required this.imageUrl,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: 300,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, size: 50),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Calories: $calories',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingredients:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '''
- 1 ½ cups (195 grams) all-purpose flour
- 3 ½ teaspoons baking powder
- 1 teaspoon salt
- 1 tablespoon granulated sugar
- 1 ¼ cups (295 ml) milk
- 1 egg
- 3 tablespoons (43 grams) unsalted butter, melted
                    ''',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preparation Steps:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '''
1. Whisk flour, baking powder, salt, and sugar in a bowl.
2. In another bowl, whisk milk, egg, and melted butter.
3. Pour the wet mixture into the dry mixture and stir gently.
4. Heat a skillet over medium heat and grease lightly.
5. Pour batter onto the skillet, cook until bubbles form, then flip.
6. Serve warm with syrup or toppings of choice.
                    ''',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
