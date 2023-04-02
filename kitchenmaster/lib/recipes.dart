// ignore_for_file: prefer_const_constructors, unnecessary_new

import 'package:flutter/material.dart';
import 'package:favorite_button/favorite_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'indivRecipes.dart';

class RecipePage extends StatefulWidget {
  RecipePage({Key? key}) : super(key: key);

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class Recipe {
  final CollectionReference recipes =
      FirebaseFirestore.instance.collection('Recipes');

  List<String> generated = [];
  List recipeDetails = [];

  void fetchRecipesName() async {
    QuerySnapshot querySnapshot = await recipes.get();

    querySnapshot.docs.forEach((document) {
      String name = document.get("Name");
      print(name);
    });
  }

  void fetchMatchingRecipes(List<String> ingredients) async {
    QuerySnapshot querySnapshot = await recipes.get();
    List<dynamic> recipeDB;
    generated = [];
    recipeDetails = [];
    querySnapshot.docs.forEach((document) {
      //gets array of String type from Ingredient column in database
      recipeDB = document.get("Ingredients");
      //checks if the food items in fridge is a subset of items in recipe
      if (ingredients.toSet().length ==
          recipeDB.toSet().intersection(ingredients.toSet()).length) {
        //prints the name of recipes that matches the food items in fridge
        print(document.get("Name"));
        generated.add(document.get("Name"));
        recipeDetails.add(document);
      } else {}
    });
  }

  Future<List> getRecipes() async {
    debugPrint('getting recipes');
    //fetchRecipesName();
    //ingredients passed in are case and space sensitive
    List<String> smoothie1 = ["banana", "strawberry", "apple juice"];
    List<String> smoothie2 = ["kiwi", "banana", "mango", "pineapple juice"];
    fetchMatchingRecipes(smoothie2);
    return await recipeDetails;
  }
}

class _RecipePageState extends State<RecipePage> {
  Recipe test = new Recipe();
  List<String> generatedRecipes = [];

  List<String> resetRecipes() {
    // test.generated = [];
    test.getRecipes();
    setState(() {});
    return [];
  }

  Future<bool> checkSaved(String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedRecipes');
    var querySnapshots = await savedRef.get();
    for (var snapshot in querySnapshots.docs) {
      if (snapshot.get('name') == name) {
        return true;
      }
    }
    return false;
  }

  //update firebase
  void addSaved(String id, String recipeName, DocumentReference recipe) async {
    print("Saving recipe...");
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedRecipes');
    DocumentReference newSavedRef =
        await savedRef.add({'id': id, 'name': recipeName, 'recipe': recipe});

    // final newAlertId = generateUniqueId(newAlertRef.id);
    print("Recipe saved!");
  }

  void removeSaved(String name) async {
    //delete in firebase
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedRecipes');
    var querySnapshots = await savedRef.get();
    for (var snapshot in querySnapshots.docs) {
      if (snapshot.get('name') == name) {
        savedRef.doc(snapshot.id).delete().then((value) {
          debugPrint('Recipe removed successfully');
        }).catchError((error) {
          debugPrint('Failed to remove recipe: $error');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
          SizedBox(height: 50),
          const Text('Recipes',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inria Serif',
                  fontSize: 35,
                  fontWeight: FontWeight.normal,
                  height: 1)),
          SizedBox(height: 30),
          ElevatedButton(
            child: Text('Generate Recipes'),
            onPressed: () async {
              generatedRecipes = resetRecipes();
              setState(() {});
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            // child: StreamBuilder(
            //   stream:
            //       FirebaseFirestore.instance.collection('Recipes').snapshots(),
            //   builder:
            //       (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            //     if (!snapshot.hasData) {
            //       return Center(
            //         child: CircularProgressIndicator(),
            //       );
            //     }
            child: FutureBuilder<List>(
              future: test.getRecipes(),
              builder: (context, snapshot) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          snapshot.data!.length,
                          (index) {
                            return Card(
                                elevation: 0,
                                color: Color.fromARGB(0, 255, 255, 255),
                                child: Center(
                                    child: SizedBox(
                                        width: 350,
                                        height: 60,
                                        child: Row(children: <Widget>[
                                          TextButton(
                                            child: Text(snapshot.data?[index]
                                                    .get("Name") ??
                                                "null"),
                                            onPressed: () {
                                              String recipeName = snapshot
                                                  .data![index]
                                                  .get("Name");
                                              List<dynamic> ingredients =
                                                  snapshot.data![index]
                                                      .get("Ingredients");
                                              String procedure = snapshot
                                                  .data![index]
                                                  .get("Procedures");
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          indivRecipePage(
                                                              recipeName:
                                                                  recipeName,
                                                              ingredients:
                                                                  ingredients,
                                                              procedure:
                                                                  procedure)));
                                            },
                                          ),
                                          // FutureBuilder<bool>(
                                          //     future: checkSaved(snapshot
                                          //         .data?[index]
                                          //         .get("Name")),
                                          //     builder: (c, s) {
                                          //       print("isFavorite: ${s.data}");
                                          //       bool favourite = false;
                                          //       if (s.data == true) {
                                          //         favourite = true;
                                          //       }
                                          // return
                                          FavoriteButton(
                                            isFavorite: false,
                                            valueChanged: (_isFavorite) {
                                              if (_isFavorite) {
                                                var recipe = FirebaseFirestore
                                                    .instance
                                                    .collection("Recipes")
                                                    .doc(snapshot.data?[index]
                                                        .get("Name"));
                                                String id =
                                                    UniqueKey().toString();
                                                print(id);
                                                addSaved(
                                                    id,
                                                    snapshot.data?[index]
                                                        .get("Name"),
                                                    recipe);
                                              } else if (!_isFavorite) {
                                                removeSaved(snapshot
                                                    .data?[index]
                                                    .get("Name"));
                                              }
                                            },
                                          )
                                          // })
                                        ]))));
                          },
                        ),
                      );
              },
            ),
          )
        ]))));
  }
}
//
// new ListView.builder(
// itemCount: generatedRecipes.length,
// itemBuilder: (BuildContext context, int index) {
// // return ListView(
// //   children: snapshot.data!.docs.map((document) {
// return Card(
// elevation: 0,
// color: Color.fromARGB(0, 255, 255, 255),
// child: Center(
// child: SizedBox(
// width: 350,
// height: 60,
// child: Column(children: <Widget>[
// Row(children: <Widget>[
// TextButton(
// child: Text(generatedRecipes[index]),
// onPressed: () {
// // navigate to indiv recipe page
// },
// ),
// FavoriteButton(
// valueChanged: (_isFavorite) {
// if (_isFavorite) {
// RecipePage.addFavourites(
// generatedRecipes[index]);
// print(RecipePage.getFavourites());
// } else if (!_isFavorite) {
// RecipePage.removeFavourites(
// generatedRecipes[index]);
// print(RecipePage.getFavourites());
// }
// },
// )
// ])
// ]))));
// }),
