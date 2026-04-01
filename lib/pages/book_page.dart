import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'riwayat_peminjaman_page.dart';
import 'login_page.dart';

class BookPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String kelas;
  final String nisn;
  final String alamat;
  final String noHp;

  const BookPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.kelas,
    required this.nisn,
    required this.alamat,
    required this.noHp,
  });

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> books = [];
  List<String> borrowedBookIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchBorrowedBooks();
  }

  Future<void> _fetchBooks() async {
    final response = await supabase.from('books').select();
    setState(() {
      books = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> _fetchBorrowedBooks() async {
    final response = await supabase
        .from('loans')
        .select('book_id')
        .eq('user_id', widget.userId)
        .eq('status', 'dipinjam');

    setState(() {
      borrowedBookIds =
          (response as List).map<String>((item) => item['book_id'].toString()).toList();
    });
  }

  Future<void> _borrowBook(Map<String, dynamic> book) async {
    await supabase.from('loans').insert({
      'user_id': widget.userId,
      'book_id': book['id'],
      'tanggal_pinjam': DateTime.now().toIso8601String(),
      'status': 'dipinjam',
    });

    await supabase.from('books').update({
      'stok': book['stok'] - 1,
    }).eq('id', book['id']);

    await _fetchBooks();
    await _fetchBorrowedBooks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Berhasil meminjam "${book['judul']}"')),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Buku'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    nama: widget.nama,
                    kelas: widget.kelas,
                    nisn: widget.nisn,
                    alamat: widget.alamat,
                    noHp: widget.noHp,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiwayatPeminjamanPage(userId: widget.userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final isBorrowed = borrowedBookIds.contains(book['id'].toString());
                final stok = book['stok'] ?? 0;

                return Card(
                  color: const Color(0xFF0E1626),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(book['judul'] ?? '-'),
                    subtitle: Text('${book['penulis'] ?? '-'} • Stok: $stok'),
                    trailing: isBorrowed
                        ? const Text('Dipinjam', style: TextStyle(color: Colors.white54))
                        : stok > 0
                            ? OutlinedButton(
                                onPressed: () => _borrowBook(book),
                                child: const Text('Pinjam'),
                              )
                            : const Text('Habis', style: TextStyle(color: Colors.red)),
                  ),
                );
              },
            ),
    );
  }
}