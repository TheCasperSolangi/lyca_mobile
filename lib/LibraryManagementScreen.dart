import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class Book {
  final String libraryCode;
  final String title;
  final String author;
  final String genre;
  final String isbn;
  final String shortDescription;
  final String longDescription;
  final String bookCoverUrl;
  final int availableCopies;

  const Book({
    required this.libraryCode,
    required this.title,
    required this.author,
    required this.genre,
    required this.isbn,
    required this.shortDescription,
    required this.longDescription,
    required this.bookCoverUrl,
    this.availableCopies = 0,
  });
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Enhanced book list with more detailed information
  final List<Book> rentedBooks = [
    Book(
      libraryCode: 'LIB001',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      genre: 'Classic Literature',
      isbn: '978-0743273565',
      shortDescription: 'A tragic love story set in the Roaring Twenties.',
      longDescription: 'The Great Gatsby explores themes of decadence, idealism, social upheaval, and resistance to change, creating a portrait of the Jazz Age that has been described as a cautionary tale about the American Dream.',
      bookCoverUrl: 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
      
    ),
    Book(
      libraryCode: 'LIB002',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      genre: 'Classic Fiction',
      isbn: '978-0446310789',
      shortDescription: 'A powerful story of racial injustice and moral growth.',
      longDescription: 'Set in the racially charged Southern United States, this novel explores complex issues of prejudice, compassion, and human dignity through the eyes of a young girl.',
      bookCoverUrl: 'https://m.media-amazon.com/images/I/71FxgtFKcQL._AC_UF1000,1000_QL80_.jpg',
  
    ),
  ];

  final List<Book> availableBooks = [
    Book(
      libraryCode: 'LIB003',
      title: '1984',
      author: 'George Orwell',
      genre: 'Dystopian Fiction',
      isbn: '978-0451524935',
      shortDescription: 'A chilling dystopian vision of totalitarian control.',
      longDescription: 'A groundbreaking novel that explores the dangers of government overreach, totalitarian control, and the manipulation of truth in a dystopian future.',
      bookCoverUrl: 'https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg',
      availableCopies: 3, 
    ),
    Book(
      libraryCode: 'LIB004',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      genre: 'Classic Romance',
      isbn: '978-0141439518',
      shortDescription: 'A witty exploration of love, marriage, and social status.',
      longDescription: 'A masterpiece of romantic fiction that critiques the social expectations of 19th-century English society through the story of Elizabeth Bennet and Mr. Darcy.',
      bookCoverUrl: 'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_UF1000,1000_QL80_.jpg',
      availableCopies: 2, 
    ),
    Book(
      libraryCode: 'LIB005',
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      genre: 'Fantasy',
      isbn: '978-0547928227',
      shortDescription: 'An epic fantasy adventure of a hobbit\'s unexpected journey.',
      longDescription: 'A beloved fantasy novel that follows Bilbo Baggins on a thrilling quest across Middle-earth, encountering dragons, elves, and magical creatures.',
      bookCoverUrl: 'https://m.media-amazon.com/images/I/710+HcoP38L._AC_UF1000,1000_QL80_.jpg',
      availableCopies: 1, 
    ),
  ];

  void _showBookDetails(Book book, bool isRented) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        book.bookCoverUrl,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'by ${book.author}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Genre', book.genre),
                  _buildDetailRow('ISBN', book.isbn),
                  _buildDetailRow('Library Code', book.libraryCode),
                  if (isRented) _buildDetailRow('Due Date', '123'),
                  if (!isRented) _buildDetailRow('Available Copies', book.availableCopies.toString()),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    book.longDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[600],
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleBookAction(book, isRented);
                      },
                      child: Text(
                        isRented ? 'Mark as Returned' : 'Rent Book',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBookAction(Book book, bool isRented) {
    setState(() {
      if (isRented) {
        // Mark as returned
        rentedBooks.removeWhere((b) => b.libraryCode == book.libraryCode);
        
        // Add back to available books
        availableBooks.add(book.copyWith(availableCopies: 1));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.title} marked as returned'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        // Rent book
        availableBooks.removeWhere((b) => b.libraryCode == book.libraryCode);
        
        // Add to rented books with a due date
        rentedBooks.add(book.copyWith(
          dueDate: DateTime.now().add(const Duration(days: 14)),
        ));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.title} rented successfully'),
            backgroundColor: Colors.deepPurple[600],
          ),
        );
      }
    });
  }

  void _navigateToAvailableBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableBooksScreen(
          availableBooks: availableBooks,
          onBookSelected: (book) {
            _showBookDetails(book, false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Your Rented Books',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
          ),
          Expanded(
            child: rentedBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No books rented yet',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      itemCount: rentedBooks.length,
                      itemBuilder: (context, index) {
                        final book = rentedBooks[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      book.bookCoverUrl,
                                      width: 50,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    book.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Due: 12',
                                   
                                  ),
                                  onTap: () => _showBookDetails(book, true),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _navigateToAvailableBooks,
                                  icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Browse Books',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference <= 3) {
      return Colors.orange; // Due soon
    } else {
      return Colors.green; // Plenty of time
    }
  }
}

class AvailableBooksScreen extends StatefulWidget {
  final List<Book> availableBooks;
  final Function(Book) onBookSelected;

  const AvailableBooksScreen({
    super.key,
    required this.availableBooks,
    required this.onBookSelected,
  });

  @override
  _AvailableBooksScreenState createState() => _AvailableBooksScreenState();
}

class _AvailableBooksScreenState extends State<AvailableBooksScreen> {
  List<Book> _filteredBooks = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBooks = widget.availableBooks;
  }

  void _filterBooks(String query) {
    setState(() {
      _filteredBooks = widget.availableBooks
          .where((book) => 
            book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase()) ||
            book.genre.toLowerCase().contains(query.toLowerCase())
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Available Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple[600],
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple[600]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onChanged: _filterBooks,
            ),
          ),
          Expanded(
            child: _filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No books found',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredBooks[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () => widget.onBookSelected(book),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(15),
                                        ),
                                        child: Image.network(
                                          book.bookCoverUrl,
                                          height: 250,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple[800],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              book.author,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Available: ${book.availableCopies}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: book.availableCopies > 0 
                                                      ? Colors.green[700] 
                                                      : Colors.red[700],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.book,
                                                  color: Colors.deepPurple[600],
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Extension method to create a copy of Book with optional modifications
extension BookCopyWith on Book {
  Book copyWith({
    String? libraryCode,
    String? title,
    String? author,
    String? genre,
    String? isbn,
    String? shortDescription,
    String? longDescription,
    String? bookCoverUrl,
    DateTime? dueDate,
    int? availableCopies,
  }) {
    return Book(
      libraryCode: libraryCode ?? this.libraryCode,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      isbn: isbn ?? this.isbn,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      bookCoverUrl: bookCoverUrl ?? this.bookCoverUrl,
   
      availableCopies: availableCopies ?? this.availableCopies,
    );
  }
}