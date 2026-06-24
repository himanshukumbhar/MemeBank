import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://bvnfeyizfxrniyxqbkrv.supabase.co',
    anonKey: 'sb_publishable_eQE0AEuv3ecJJxiNCSN59g_MKUi4QxN',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemeBank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MemeBankHome(),
    );
  }
}

class MemeBankHome extends StatefulWidget {
  const MemeBankHome({super.key});

  @override
  State<MemeBankHome> createState() => _MemeBankHomeState();
}

class _MemeBankHomeState extends State<MemeBankHome> {
  final List<String> _categories = ['Trending', 'Gaming', 'Funny', 'Crypto', 'Coding'];
  String _selectedCategory = 'Trending';
  final List<dynamic> _feedItems = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMemes();
  }

  Future<void> _fetchMemes() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('memes')
          .select()
          .eq('category', _selectedCategory)
          .order('id', ascending: false);

      _feedItems.clear();
      for (var i = 0; i < data.length; i++) {
        _feedItems.add(data[i]);
        if ((i + 1) % 4 == 0) {
          _feedItems.add({'isAd': true});
        }
      }
    } catch (e) {
      debugPrint("Error fetching memes: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "MemeBank",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent, fontSize: 24),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.yellowAccent))
                : RefreshIndicator(
                    onRefresh: _fetchMemes,
                    child: ListView.builder(
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        final item = _feedItems[index];
                        if (item is Map && item.containsKey('isAd')) {
                          return _buildAdBannerPlaceholder();
                        }
                        return MemeCard(meme: item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          bool isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: Colors.yellowAccent,
              backgroundColor: Colors.grey[900],
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
                _fetchMemes();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdBannerPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 60,
      width: double.infinity,
      color: Colors.grey[900],
      child: const Center(
        child: Text("Google AdMob Banner Ad", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

class MemeCard extends StatefulWidget {
  final dynamic meme;
  const MemeCard({super.key, required this.meme});

  @override
  State<MemeCard> createState() => _MemeCardState();
}

class _MemeCardState extends State<MemeCard> {
  VideoPlayerController? _videoController;
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    isVideo = widget.meme['meme_type'] == 'video';
    if (isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.meme['file_url']))
        ..initialize().then((_) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.grey[950]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.yellowAccent, child: Icon(Icons.person, color: Colors.black)),
            title: const Text("Anonymous Banker", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(widget.meme['category'], style: const TextStyle(color: Colors.grey)),
          ),
          GestureDetector(
            onTap: () {
              if (isVideo && _videoController != null) {
                _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
              }
            },
            child: AspectRatio(
              aspectRatio: isVideo ? (_videoController?.value.aspectRatio ?? 16 / 9) : 1,
              child: isVideo
                  ? (_videoController?.value.isInitialized ?? false
                      ? VideoPlayer(_videoController!)
                      : const Center(child: CircularProgressIndicator(color: Colors.yellowAccent)))
                  : CachedNetworkImage(
                      imageUrl: widget.meme['file_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Text('${widget.meme['likes_count'] ?? 0} likes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.meme['title'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

