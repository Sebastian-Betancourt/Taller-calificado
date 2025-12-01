import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex & Dog API',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Color(0xFFF2EDF5),
        fontFamily: 'Roboto',
      ),
      home: PokemonList(),
    );
  }
}

class PokemonList extends StatefulWidget {
  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;

  TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _searchedPokemon;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      final List results = data['results'];

      List<Map<String, dynamic>> pokemonWithImages = [];
      for (var pokemon in results) {
        final detailsResponse = await http.get(Uri.parse(pokemon['url']));
        final detailsData = json.decode(detailsResponse.body);

        pokemonWithImages.add({
          'name': pokemon['name'],
          'image': detailsData['sprites']['front_default'],
        });
      }

      setState(() {
        _pokemonList = pokemonWithImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  Future<void> searchPokemon(String name) async {
    if (name.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchedPokemon = null;
    });
    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _searchedPokemon = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  Widget buildPokemonCard() {
    final data = _searchedPokemon!;
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFFF3F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Image.network(
                data['sprites']['front_default'],
                height: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),
              Text(
                data['name'].toString().toUpperCase(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Divider(height: 25),
              Text("Altura: ${data['height']}", style: TextStyle(fontSize: 16)),
              Text("Peso: ${data['weight']}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(
                "Tipo(s): " + data['types'].map((t) => t['type']['name']).join(', '),
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPokemonList() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(top: 10),
        itemCount: _pokemonList.length,
        itemBuilder: (context, index) {
          final pokemon = _pokemonList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: pokemon['image'] != null
                  ? Image.network(pokemon['image'])
                  : Icon(Icons.image_not_supported),
            ),
            title: Text(
              pokemon['name'][0].toUpperCase() + pokemon['name'].substring(1),
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Buscar Pokémon...",
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
            onSubmitted: (value) => searchPokemon(value.trim().toLowerCase()),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Menú")),
            ListTile(
              title: Text("Actividad 2 - Dog API"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DogApiPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_searchedPokemon != null) buildPokemonCard(),
                buildPokemonList(),
              ],
            ),
    );
  }
}

// 🐶 Actividad 2 - Dog API
class DogApiPage extends StatefulWidget {
  @override
  _DogApiPageState createState() => _DogApiPageState();
}

class _DogApiPageState extends State<DogApiPage> {
  String? imageUrl;
  bool _loading = false;

  Future<void> fetchDogImage() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/image/random'));
      final data = json.decode(response.body);
      setState(() {
        imageUrl = data['message'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDogImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dog API")),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageUrl != null)
                    Image.network(imageUrl!, height: 250, fit: BoxFit.cover),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchDogImage,
                    child: Text("Obtener otra imagen"),
                  )
                ],
              ),
      ),
    );
  }
}
