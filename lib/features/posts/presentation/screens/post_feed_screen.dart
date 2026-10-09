import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/loading_indicator.dart';
import '../../../../widgets/offline_banner.dart';
import '../../domain/entities/post.dart';
import '../controllers/post_controller.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({super.key});

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  final _searchController = TextEditingController();

  static const List<String> popularTags = [
    'all',
    'history',
    'crime',
    'mystery',
    'love',
    'classic',
    'english',
    'fiction',
    'french',
    'american',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PostController>();
      if (controller.posts.isEmpty) {
        controller.fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search community posts & discussions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.fetchPosts();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (q) => controller.searchPosts(q),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 6),
              // Tags Bar
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tag = popularTags[index];
                    final isSelected = controller.selectedTag == tag;

                    return ChoiceChip(
                      label: Text('#$tag'),
                      selected: isSelected,
                      onSelected: (_) => controller.filterByTag(tag),
                      selectedColor: AppTheme.secondaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _buildFeed(context, controller)),
        ],
      ),
    );
  }

  Widget _buildFeed(BuildContext context, PostController controller) {
    if (controller.isLoading && controller.posts.isEmpty) {
      return const LoadingIndicator(message: 'Loading community feed...');
    }

    if (controller.state == PostState.error && controller.posts.isEmpty) {
      return ErrorView(
        message: controller.errorMessage ?? 'Failed to load posts',
        onRetry: () => controller.fetchPosts(forceRefresh: true),
      );
    }

    if (controller.posts.isEmpty) {
      return const Center(child: Text('No posts found matching the filter.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchPosts(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = controller.posts[index];
          return _buildPostCard(context, post, controller);
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post, PostController controller) {
    final theme = Theme.of(context);
    final isLiked = controller.isLiked(post.id);
    final displayLikes = post.likes + (isLiked ? 1 : 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withAlpha(40),
                  child: Text(
                    'U${post.userId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User #${post.userId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${post.views} views', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post Title
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Post Body
            Text(
              post.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Tags
            if (post.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$t',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const Divider(height: 24),

            // Engagement Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.toggleLike(post.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: isLiked ? AppTheme.primaryColor : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$displayLikes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isLiked ? AppTheme.primaryColor : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dislikes
                Row(
                  children: [
                    Icon(Icons.thumb_down_alt_outlined, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${post.dislikes}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                // Comments Button
                TextButton.icon(
                  onPressed: () => _showCommentsSheet(context, post.id, controller),
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  label: const Text('Comments', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, int postId, PostController controller) {
    controller.loadComments(postId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<PostController>(
          builder: (context, ctrl, _) {
            final comments = ctrl.getComments(postId);
            final isLoading = ctrl.isLoadingComments(postId);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comments (${comments?.length ?? 0})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : (comments == null || comments.isEmpty)
                                ? const Center(child: Text('No comments yet.'))
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: comments.length,
                                    separatorBuilder: (_, __) => const Divider(height: 16),
                                    itemBuilder: (context, index) {
                                      final c = comments[index];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 12,
                                                child: Icon(Icons.person, size: 14),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                c.userFullName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '@${c.username}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            c.body,
                                            style: const TextStyle(fontSize: 13, height: 1.3),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
