import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/game_state_models.dart';
import '../../domain/entities/story_models.dart';
import '../../data/datasources/story_local_datasource.dart';
import '../../data/datasources/story_remote_datasource.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../cubit/language_cubit.dart';
import '../cubit/save_cubit.dart';
import '../cubit/story_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../widgets/glass_container.dart';
import '../widgets/auth_gate.dart';
import '../cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';
import 'story_play_screen.dart';
import 'three_d_game_screen.dart';

class LibraryScreen extends StatefulWidget {
  final SaveSlot? resumeFromSlot;

  const LibraryScreen({super.key, this.resumeFromSlot});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late StoryRepositoryImpl _storyRepository;
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _storyRepository = StoryRepositoryImpl(
      localDataSource: StoryLocalDataSourceImpl(),
      remoteDataSource: StoryRemoteDataSourceImpl(),
    );
    _loadStories();

    // Check if we need to auto-resume a slot
    if (widget.resumeFromSlot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resumeStory(widget.resumeFromSlot!);
      });
    }
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final lang = context.read<LanguageCubit>().state;
      final stories = await _storyRepository.getStoriesList(lang);
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Start New Story ---
  Future<void> _startStory(Story story, AppLocalizations l10n) async {
    final saveCubit = context.read<SaveCubit>();
    final globalState = saveCubit.state.globalState;
    
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.userProfile.isAdmin;
    
    // Check lock status
    final isFree = story.id == 'horror_crypt' || story.is3d; // All 3D flagship stories are free!
    final isUnlocked = isAdmin || globalState.unlockedChapters.contains(story.id);

    if (!isFree && !isUnlocked) {
      // Show Unlock Dialog
      final cost = 3;
      final success = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎟️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    story.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('cost_tickets', replace: '{n}', withVal: cost.toString()),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.translate('back'), style: const TextStyle(color: Colors.white60)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (globalState.tickets >= cost) {
                            Navigator.pop(ctx, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Not enough tickets!')),
                            );
                            Navigator.pop(ctx, false);
                          }
                        },
                        child: Text(l10n.translate('unlock')),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ) ?? false;

      if (success) {
        final ok = await saveCubit.unlockChapter(story.id, cost: cost);
        if (!ok) return; // double check
      } else {
        return; // User canceled or had no tickets
      }
    }

    if (!mounted) return;

    // Load full story details and launch 3D play screen
    try {
      final lang = context.read<LanguageCubit>().state;
      final details = await _storyRepository.getStoryDetails(story.id, lang);
      
      if (!mounted) return;
      
      // Update dynamic UI theme and start story
      context.read<ThemeCubit>().setStoryTheme(story.id);
      context.read<StoryCubit>().startNewStory(details, story.id);

      if (story.is3d) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ThreeDGameScreen(storyId: story.id, title: story.title),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryPlayScreen(storyId: story.id, storyRepository: _storyRepository),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start story: $e')),
      );
    }
  }

  // --- Resume Story ---
  Future<void> _resumeStory(SaveSlot slot) async {
    try {
      final lang = context.read<LanguageCubit>().state;
      final details = await _storyRepository.getStoryDetails(slot.storyId!, lang);
      
      if (!mounted) return;
      
      // Update dynamic UI theme
      context.read<ThemeCubit>().setStoryTheme(slot.storyId!);
      context.read<StoryCubit>().resumeStory(
            details,
            slot.storyId!,
            slot.currentNodeId!,
            slot.playerState!,
            slot.history,
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryPlayScreen(storyId: slot.storyId!, storyRepository: _storyRepository),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume story: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(language);
    final globalState = context.watch<SaveCubit>().state.globalState;

    // Filter stories based on selected category tab
    final filteredStories = _stories.where((story) {
      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'horror' && story.id.contains('horror')) return true;
      if (_selectedCategory == 'comedy' && story.id.contains('comedy')) return true;
      if (_selectedCategory == 'history' && story.id.contains('history')) return true;
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('library')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Role & Tickets display
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isAdmin = authState is AuthAuthenticated && authState.userProfile.isAdmin;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    borderRadius: 12,
                    opacity: 0.1,
                    child: Text(
                      isAdmin ? '👑 Admin' : '🎟️ ${globalState.tickets}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
              );
            },
            tooltip: 'Log Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Category Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryTab('all', 'الكل / All', l10n),
                  _buildCategoryTab('horror', 'رعب / Horror', l10n),
                  _buildCategoryTab('comedy', 'كوميدي / Comedy', l10n),
                  _buildCategoryTab('history', 'تاريخي / History', l10n),
                ],
              ),
            ),
          ),

          // 2. Stories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadStories, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filteredStories.isEmpty
                        ? const Center(child: Text('No stories found in this category.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredStories.length,
                            itemBuilder: (context, index) {
                              final story = filteredStories[index];
                              
                              final authState = context.watch<AuthCubit>().state;
                              final isAdmin = authState is AuthAuthenticated && authState.userProfile.isAdmin;
                              
                              final isFree = story.id == 'horror_crypt';
                              final isUnlocked = isAdmin || globalState.unlockedChapters.contains(story.id);

                              return ParallaxCard(
                                child: Card(
                                  color: const Color(0xFF162235),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Colors.white10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: () => _startStory(story, l10n),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Story Cover Placeholder Image with Gradient Overlay
                                        Stack(
                                          children: [
                                            Container(
                                              height: 180,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: _getGenreGradients(story.id),
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: story.coverImage.startsWith('http')
                                                  ? Image.network(
                                                      story.coverImage,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Center(
                                                          child: Icon(
                                                            _getGenreIcon(story.id),
                                                            size: 64,
                                                            color: Colors.white54,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Image.asset(
                                                      story.coverImage,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Center(
                                                          child: Icon(
                                                            _getGenreIcon(story.id),
                                                            size: 64,
                                                            color: Colors.white54,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (story.isRemote) ...[
                                                    GlassContainer(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      borderRadius: 8,
                                                      opacity: 0.25,
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.cloud_queue, size: 14, color: Color(0xFF00E5FF)),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Cloud',
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  GlassContainer(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    borderRadius: 8,
                                                    opacity: 0.2,
                                                    child: Text(
                                                      story.genre,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isFree && !isUnlocked)
                                              Positioned(
                                                top: 12,
                                                left: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.black54,
                                                  ),
                                                  child: const Icon(Icons.lock, color: Colors.orangeAccent, size: 20),
                                                ),
                                              ),
                                            if (!isFree && isAdmin && !globalState.unlockedChapters.contains(story.id))
                                              Positioned(
                                                top: 12,
                                                left: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.black54,
                                                  ),
                                                  child: const Icon(Icons.star, color: Colors.amberAccent, size: 20),
                                                ),
                                              ),
                                          ],
                                        ),
                                        // Story text details
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                story.title,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00E5FF),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                story.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, height: 1.4),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${l10n.translate('difficulty')}: ${story.difficulty}',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                                                  ),
                                                  Text(
                                                    '${l10n.translate('age_rating')}: ${story.ageRating}',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, String label, AppLocalizations l10n) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF00E5FF),
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }

  List<Color> _getGenreGradients(String storyId) {
    if (storyId.contains('horror')) {
      return [const Color(0xFF3A0007), const Color(0xFF1A0002)];
    } else if (storyId.contains('comedy')) {
      return [const Color(0xFFFFB300), const Color(0xFFFF6F00)];
    } else if (storyId.contains('history')) {
      return [const Color(0xFF8D6E63), const Color(0xFF4E342E)];
    }
    return [const Color(0xFF162235), const Color(0xFF0F172A)];
  }

  IconData _getGenreIcon(String storyId) {
    if (storyId.contains('horror')) return Icons.dark_mode;
    if (storyId.contains('comedy')) return Icons.sentiment_very_satisfied;
    if (storyId.contains('history')) return Icons.history_edu;
    return Icons.menu_book;
  }
}

class ParallaxCard extends StatefulWidget {
  final Widget child;

  const ParallaxCard({super.key, required this.child});

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tiltAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    // Relative position from center: -1.0 to 1.0
    final localPosition = details.localPosition;
    final rx = (localPosition.dx / size.width) * 2 - 1;
    final ry = (localPosition.dy / size.height) * 2 - 1;

    _tiltAnimation = Tween<Offset>(
      begin: _tiltAnimation.value,
      end: Offset(rx.clamp(-1.0, 1.0), ry.clamp(-1.0, 1.0)),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward(from: 0.0);
  }

  void _onTapUp() {
    _tiltAnimation = Tween<Offset>(
      begin: _tiltAnimation.value,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (event) {
            if (size.width == 0 || size.height == 0) return;
            final rx = (event.localPosition.dx / size.width) * 2 - 1;
            final ry = (event.localPosition.dy / size.height) * 2 - 1;
            setState(() {
              _tiltAnimation = AlwaysStoppedAnimation(Offset(rx.clamp(-1.0, 1.0), ry.clamp(-1.0, 1.0)));
            });
          },
          onExit: (_) {
            _tiltAnimation = Tween<Offset>(
              begin: _tiltAnimation.value,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ));
            _animationController.forward(from: 0.0);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) => _onTapDown(details, size),
            onTapUp: (_) => _onTapUp(),
            onTapCancel: _onTapUp,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final currentTilt = _tiltAnimation.value;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(currentTilt.dy * -0.07) // subtle tilt rotateX
                    ..rotateY(currentTilt.dx * 0.07), // subtle tilt rotateY
                  alignment: FractionalOffset.center,
                  child: widget.child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
