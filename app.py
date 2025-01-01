from flask import Flask, request, jsonify
import pickle
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
import random
import requests
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
import nltk
import re

# Initialize Flask app
app = Flask(__name__)

# Load the trained model and vectorizer
model_path = r"./trained_model.sav"
vectorizer_path = r"./vectorizer.sav"
logistic_regression_model = pickle.load(open(model_path, 'rb'))
vectorizer = pickle.load(open(vectorizer_path, 'rb'))

# Load dataset for clustering
data_path = r"./food_choices.csv"
data = pd.read_csv(data_path)
selected_columns = ['calories_chicken', 'calories_day', 'coffee', 'soup']
data = data[selected_columns].dropna()
data = data.apply(pd.to_numeric, errors='coerce').dropna()

# PCA and KMeans setup
pca = PCA(n_components=2)
reduced_data = pca.fit_transform(data)
kmeans = KMeans(n_clusters=3, random_state=0)
kmeans.fit(reduced_data)

# Food recommendations for each cluster
food_recommendations = {
    0: ["Pasta", "Salad", "Fruit Salad", "Grilled Vegetables", "Quinoa Bowl", "Avocado Toast"],
    1: ["Burger", "Pizza", "Fries", "Hot Dog", "Fried Chicken", "Mac and Cheese"],
    2: ["Soup", "Sandwich", "Smoothie", "Steak", "Seafood Platter", "Sushi"]
}

# Spoonacular API key
spoonacular_api_key = "87704e214c4142bd80142ac1f8202776"

# Helper functions

def lemmatize(content):
    nltk.download('stopwords', quiet=True)
    nltk.download('wordnet', quiet=True)
    lemmatizer = WordNetLemmatizer()
    content = re.sub('[^a-zA-Z]', ' ', content).lower().split()
    return ' '.join([lemmatizer.lemmatize(word) for word in content if word not in stopwords.words('english')])

def get_dynamic_recommendations(mood, pca, kmeans, food_recommendations, total_items=3):
    try:
        mood_reduced = pca.transform([mood])
        cluster_distances = kmeans.transform(mood_reduced)[0]
        sorted_clusters = np.argsort(cluster_distances)
        recommendations = set()
        for cluster in sorted_clusters:
            if cluster in food_recommendations:
                items = food_recommendations[cluster]
                if items:
                    recommendations.add(random.choice(items))
            if len(recommendations) >= total_items:
                break
        return list(recommendations)
    except Exception as e:
        return ["No recommendations available"]

def get_recipes_with_details(food_items, api_key):
    recipes = {}
    base_url_search = "https://api.spoonacular.com/recipes/complexSearch"
    base_url_info = "https://api.spoonacular.com/recipes/{id}/information"
    for food in food_items:
        try:
            search_params = {"query": food, "number": 1, "apiKey": api_key}
            response = requests.get(base_url_search, params=search_params)
            if response.status_code == 200:
                search_data = response.json()
                if search_data.get("results"):
                    recipe_id = search_data["results"][0].get("id")
                    if recipe_id:
                        info_url = base_url_info.format(id=recipe_id)
                        info_response = requests.get(info_url, params={"apiKey": api_key})
                        if info_response.status_code == 200:
                            recipe_info = info_response.json()
                            recipes[food] = {
                                "title": recipe_info.get("title", "No Title"),
                                "ingredients": [ingredient["name"] for ingredient in recipe_info.get("extendedIngredients", [])],
                                "instructions": recipe_info.get("instructions", "No Instructions Available")
                            }
                        else:
                            recipes[food] = {"error": f"Could not fetch details for {food} (Status {info_response.status_code})"}
                else:
                    recipes[food] = {"error": "No results found in search"}
            else:
                recipes[food] = {"error": f"Search error (Status {response.status_code})"}
        except Exception as e:
            recipes[food] = {"error": str(e)}

    return recipes

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json
        text = data.get('text', '')
        processed_text = lemmatize(text)
        vectorized_text = vectorizer.transform([processed_text])
        prediction = logistic_regression_model.predict(vectorized_text)[0]

        mood_map = {
            'Sadness': [2, 8, 6, 3],
            'Joy': [8, 2, 4, 9],
            'Love': [7, 3, 5, 8],
            'Anger': [1, 9, 7, 2],
            'Fear': [2, 9, 8, 1],
            'Surprise': [6, 4, 3, 9]
        }

        mood = mood_map.get(prediction, [5, 5, 5, 5])
        recommendations = get_dynamic_recommendations(mood, pca, kmeans, food_recommendations)

        recipes = get_recipes_with_details(recommendations, spoonacular_api_key)

        return jsonify({
            "emotion": prediction,
            "recommendations": recommendations,
            "recipes": recipes
        })
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == '__main__':
    import os
    app.run(debug=False, host='0.0.0.0', port=int(os.environ.get("PORT", 5000)))
