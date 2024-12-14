import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manage_learning/ui/blog_events.dart';
import 'package:manage_learning/ui/blog_repository.dart';

// ImageService handles image picking operations
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }
}

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final BlogRepository _repository;
  final ImageService _imageService;
  String? imageUrl;

  BlogBloc(
      {required BlogRepository repository, required ImageService imageService})
      : _repository = repository,
        _imageService = imageService,
        super(BlogInitial()) {
    on<FetchBlogByIdEvent>((event, emit) async {
      emit(BlogLoading());
      try {
        final blog = await _repository.getBlogPostById(event.blogId);
        if (blog != null) {
          emit(BlogFetched(blog));
        } else {
          emit(BlogError('Blog not found'));
        }
      } catch (e) {
        emit(BlogError('Error fetching blog: $e'));
      }
    });

    on<UpdateMarkdownEvent>((event, emit) {
      emit(MarkdownUpdated(event.markdown));
    });

    on<PickImageEvent>((event, emit) async {
      emit(BlogLoading());
      try {
        final XFile? image = await _imageService.pickImage();
        if (image != null) {
          final path = image.path;
          emit(BlogImageUpdated(path));
        }
      } catch (e) {
        emit(BlogError('Error uploading image: $e'));
      }
    });

    on<RemoveImageEvent>((event, emit) async {
      emit(BlogLoading());
      try {
        if (imageUrl != null) {
          await _repository.deleteImage(imageUrl!);
          imageUrl = null;
        }
        emit(BlogImageUpdated(imageUrl));
      } catch (e) {
        emit(BlogError('Error deleting image: $e'));
      }
    });

    on<CreateBlogEvent>((event, emit) async {
      emit(BlogLoading());
      try {
        String markdown = event.markdown;
        final title = event.title;
        final tags = event.tags;
        final RegExp imageRegExp = RegExp(r'!\[.*?\]\((.*?)\)');
        final Iterable<RegExpMatch> matches = imageRegExp.allMatches(markdown);
        final List<String> imageUrls =
            matches.map((match) => match.group(1)!).toList();

        for (String url in imageUrls) {
          if (url.contains('localhost')) {
            final XFile imageFile = XFile(url);
            final String downloadUrl = await _repository.uploadImage(imageFile);
            markdown = markdown.replaceAll(url, downloadUrl);
          }
        }

        final blogId = await _repository.saveBlogPost(title, markdown, tags);
        final tagList = tags.split('/').where((tag) => tag.isNotEmpty).toList();
        await _repository.createTagPath(tagList, blogId, title);
        emit(BlogCreated());
      } catch (e) {
        emit(BlogError('Error saving blog post: $e'));
      }
    });

    on<UpdateBlogEvent>((event, emit) async {
      emit(BlogLoading());
      try {
        String updatedMarkdown = event.markdown;
        final upatedTitle = event.title;
        final upatedTags = event.tags;
        final String initialMarkdown = event
            .initialMarkdown; // Assuming initial markdown is passed in the event

        // Regular expression to match image URLs in markdown
        final RegExp imageRegExp = RegExp(r'!\[.*?\]\((.*?)\)');

        // Extract image URLs from initial markdown
        final Iterable<RegExpMatch> initialMatches =
            imageRegExp.allMatches(initialMarkdown);
        final List<String> initialImageUrls =
            initialMatches.map((match) => match.group(1)!).toList();

        // Extract image URLs from updated markdown
        final Iterable<RegExpMatch> updatedMatches =
            imageRegExp.allMatches(updatedMarkdown);
        final List<String> updatedImageUrls =
            updatedMatches.map((match) => match.group(1)!).toList();

        // Identify URLs that are in the initial markdown but not in the updated markdown
        final List<String> urlsToDelete = initialImageUrls
            .where((url) => !updatedImageUrls.contains(url))
            .toList();

        // Delete those URLs from Firebase Storage
        for (String url in urlsToDelete) {
          _repository.deleteImage(url);
        }

        // Process and upload new images in the updated markdown
        for (String url in updatedImageUrls) {
          if (url.contains('localhost') ||
              url.contains('manage-learning.web.app')) {
            final XFile imageFile = XFile(url);
            final String downloadUrl = await _repository.uploadImage(imageFile);
            updatedMarkdown = updatedMarkdown.replaceAll(url, downloadUrl);
          }
        }

        // Update the blog post in Firestore
        await _repository.updateBlogPost(
          event.blogId,
          upatedTitle,
          updatedMarkdown,
          upatedTags,
        );
        emit(BlogUpdated());
      } catch (e) {
        emit(BlogError('Error updating blog post: $e'));
      }
    });
  }
}
