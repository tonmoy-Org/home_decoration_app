import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const InteriorDesignerApp());
}

class InteriorDesignerApp extends StatelessWidget {
  const InteriorDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interior Designer AI',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
      ),
      home: const DesignHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DesignHomePage extends StatefulWidget {
  const DesignHomePage({super.key});

  @override
  State<DesignHomePage> createState() => _DesignHomePageState();
}

class _DesignHomePageState extends State<DesignHomePage> {
  final String _apiKey = "";
  
  Uint8List? _imageBytes;
  bool _isLoading = false;
  List<String> _generatedDesigns = [];
  List<String> _favorites = [];
  String? _errorMessage;
  String _roomType = "living room";
  String _designTheme = "modern";
  final _httpClient = http.Client();
  
  // New state variables for additional features
  List<String> _communityDesigns = [
    "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600",
    "https://images.unsplash.com/photo-1600210492493-0946911123ea?w=600",
    "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=600",
    "https://images.unsplash.com/photo-1600121848594-d8644e57abab?w=600",
  ];
  
  List<Map<String, dynamic>> _trendingProducts = [
    {
      "name": "Modern Sofa",
      "image": "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600",
      "rating": 4.8,
      "price": "\$599",
      "store": "IKEA"
    },
    {
      "name": "Minimalist Desk",
      "image": "https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=600",
      "rating": 4.5,
      "price": "\$299",
      "store": "West Elm"
    },
    {
      "name": "Industrial Lamp",
      "image": "https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600",
      "rating": 4.2,
      "price": "\$129",
      "store": "CB2"
    },
    {
      "name": "Scandinavian Chair",
      "image": "https://images.unsplash.com/photo-1517705008128-361805f42e86?w=600",
      "rating": 4.7,
      "price": "\$199",
      "store": "Article"
    },
  ];
  
  List<Map<String, dynamic>> _colorPalettes = [
    {
      "name": "Earth Tones",
      "colors": [const Color(0xFFA67C52), const Color(0xFFBFB8A8), const Color(0xFF7A6A5F), const Color(0xFF8C7B6B)]
    },
    {
      "name": "Cool Blues",
      "colors": [const Color(0xFFE1F5FE), const Color(0xFFB3E5FC), const Color(0xFF4FC3F7), const Color(0xFF0288D1)]
    },
    {
      "name": "Warm Neutrals",
      "colors": [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0), const Color(0xFF9E9E9E), const Color(0xFF616161)]
    },
    {
      "name": "Vibrant Accents",
      "colors": [const Color(0xFFFFF176), const Color(0xFFFF8A65), const Color(0xFFCE93D8), const Color(0xFF80DEEA)]
    },
  ];

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: ${e.toString()}';
      });
    }
  }

  Future<void> _generateDesigns() async {
    if (_imageBytes == null) {
      setState(() {
        _errorMessage = "Please select an image first";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _generatedDesigns.clear();
    });

    try {
      // Professional interior design prompt
      final prompt = 'A ${_designTheme} ${_roomType} Editorial Style Photo, Symmetry, Straight On, '
          'Modern Living Room, Large Window, Leather, Glass, Metal, Wood Paneling, '
          'Neutral Palette, Ikea, Natural Light, Apartment, Afternoon, Serene, Contemporary, 4k';

      final response = await _httpClient.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,  // Number of images
          'size': '1024x1024',  // Image size
          'quality': 'hd',
          'style': 'vivid',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> images = responseData['data'];
        setState(() {
          _generatedDesigns = images.map<String>((img) => img['url'] as String).toList();
          _isLoading = false;
        });
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('API Error: ${errorBody['error']['message'] ?? response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite(String imageUrl) {
    setState(() {
      if (_favorites.contains(imageUrl)) {
        _favorites.remove(imageUrl);
      } else {
        _favorites.add(imageUrl);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _imageBytes = null;
      _generatedDesigns.clear();
      _errorMessage = null;
    });
  }

  Widget _buildRoomTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _roomType,
      items: const [
        DropdownMenuItem(value: "living room", child: Text("Living Room")),
        DropdownMenuItem(value: "bedroom", child: Text("Bedroom")),
        DropdownMenuItem(value: "kitchen", child: Text("Kitchen")),
        DropdownMenuItem(value: "bathroom", child: Text("Bathroom")),
        DropdownMenuItem(value: "home office", child: Text("Home Office")),
      ],
      onChanged: (value) {
        setState(() {
          _roomType = value!;
        });
      },
      decoration: InputDecoration(
        labelText: "Room Type",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildThemeDropdown() {
    return DropdownButtonFormField<String>(
      value: _designTheme,
      items: const [
        DropdownMenuItem(value: "modern", child: Text("Modern")),
        DropdownMenuItem(value: "minimalist", child: Text("Minimalist")),
        DropdownMenuItem(value: "industrial", child: Text("Industrial")),
        DropdownMenuItem(value: "scandinavian", child: Text("Scandinavian")),
        DropdownMenuItem(value: "bohemian", child: Text("Bohemian")),
      ],
      onChanged: (value) {
        setState(() {
          _designTheme = value!;
        });
      },
      decoration: InputDecoration(
        labelText: "Design Theme",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildImageSourceButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return _imageBytes != null
        ? Column(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _imageBytes!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRoomTypeDropdown(),
              const SizedBox(height: 16),
              _buildThemeDropdown(),
            ],
          )
        : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Upload your room photo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildGeneratedDesignsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _generatedDesigns.length,
      itemBuilder: (context, index) {
        return _buildDesignItem(_generatedDesigns[index]);
      },
    );
  }

// shoaib 4955
  Widget _buildFavoritesGrid() {
    return _favorites.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),




                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon to save designs',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              return _buildDesignItem(_favorites[index]);
            },
          );
  }

  Widget _buildCommunityDesignsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _communityDesigns.length,
      itemBuilder: (context, index) {
        return _buildCommunityDesignItem(_communityDesigns[index]);
      },
    );
  }

  Widget _buildTrendingProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trendingProducts.length,
      itemBuilder: (context, index) {
        return _buildProductItem(_trendingProducts[index]);
      },
    );
  }

  Widget _buildColorPalettesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _colorPalettes.length,
      itemBuilder: (context, index) {
        return _buildColorPaletteItem(_colorPalettes[index]);
      },
    );
  }

  Widget _buildDesignItem(String imageUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _favorites.contains(imageUrl) ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: () => _toggleFavorite(imageUrl),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareDesign(imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityDesignItem(String imageUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('124', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.comment, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('23', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey[100],
                child: CachedNetworkImage(
                  imageUrl: product['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['store'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 16),
                      Text(' ${product['rating']}', style: TextStyle(color: Colors.grey[800])),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product['price'],
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite_border, color: Colors.grey[600]),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteItem(Map<String, dynamic> palette) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              palette['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: palette['colors'].map<Widget>((color) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply to Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareDesign(String imageUrl) {
    // In a real app, this would use the share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing design...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }



  Widget _buildFavoritesTab() {
    return _favorites.isEmpty
        ? _buildEmptyFavorites()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Favorites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFavoritesGrid(),
              ],
            ),
          );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the heart icon on designs to save them here for future reference',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              DefaultTabController.of(context).animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Explore Designs'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Designs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCommunityDesignsGrid(),
          const SizedBox(height: 24),
          const Text(
            'Upload Your Design',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your design with the community and get feedback',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickImage,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.teal[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload),
                SizedBox(width: 8),
                Text('Share Your Design'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Popular items our community is loving right now',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendingProductsList(),
        ],
      ),
    );
  }

  Widget _buildVisualizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _build3DVisualization(),
          const SizedBox(height: 24),
          const Text(
            'Color Palettes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try these popular color combinations in your space',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          _buildColorPalettesGrid(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AI Interior Designer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.3),
            ),
            tabs: const [
              Tab(icon: Icon(Icons.home), text: "Design"),
              Tab(icon: Icon(Icons.favorite), text: "Favorites"),
              Tab(icon: Icon(Icons.people), text: "Community"),
              Tab(icon: Icon(Icons.shopping_bag), text: "Products"),
              Tab(icon: Icon(Icons.view_in_ar), text: "3D Room"),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey[800]!,
                  Colors.teal[700]!,
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: TabBarView(
            children: [
              _buildDesignTab(),
              _buildFavoritesTab(),
              _buildCommunityTab(),
              _buildProductsTab(),
              _buildVisualizationTab(),
            ],
          ),
        ),
      ),
    );
  }
}