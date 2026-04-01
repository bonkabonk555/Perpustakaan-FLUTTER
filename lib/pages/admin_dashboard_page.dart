import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;

  // Statistik
  int totalBuku = 0;
  int totalUser = 0;
  int sedangDipinjam = 0;
  int sudahDikembalikan = 0;

  // Data
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> users = [];

  bool loadingBooks = true;
  bool loadingLoans = true;
  bool loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchBooks(),
      _fetchLoans(),
      _fetchUsers(),
      _fetchStatistik(),
    ]);
  }

  Future<void> _fetchStatistik() async {
    final b = await supabase.from('books').select();
    final u = await supabase.from('profiles').select();
    final dp = await supabase.from('loans').select().eq('status', 'dipinjam');
    final dk = await supabase.from('loans').select().eq('status', 'kembali');
    setState(() {
      totalBuku = (b as List).length;
      totalUser = (u as List).length;
      sedangDipinjam = (dp as List).length;
      sudahDikembalikan = (dk as List).length;
    });
  }

  Future<void> _fetchBooks() async {
    setState(() => loadingBooks = true);
    final data = await supabase.from('books').select().order('judul');
    setState(() {
      books = List<Map<String, dynamic>>.from(data);
      loadingBooks = false;
    });
  }

  Future<void> _fetchLoans() async {
    setState(() => loadingLoans = true);
    final data = await supabase
        .from('loans')
        .select(
          'id, status, tanggal_pinjam, user_id, book_id, books(judul), profiles(nama, kelas)',
        )
        .order('tanggal_pinjam', ascending: false);
    setState(() {
      loans = List<Map<String, dynamic>>.from(data);
      loadingLoans = false;
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => loadingUsers = true);
    final data = await supabase.from('profiles').select().order('nama');
    setState(() {
      users = List<Map<String, dynamic>>.from(data);
      loadingUsers = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1626),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Yakin ingin keluar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ── CRUD Buku ──
  void _showBookDialog({Map<String, dynamic>? book}) {
    final judulC = TextEditingController(text: book?['judul'] ?? '');
    final penulisC = TextEditingController(text: book?['penulis'] ?? '');
    final stokC = TextEditingController(text: book?['stok']?.toString() ?? '');
    final isEdit = book != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1626),
        title: Text(
          isEdit ? 'Edit Buku' : 'Tambah Buku',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Judul', judulC, Icons.book_outlined),
            const SizedBox(height: 10),
            _dialogField('Penulis', penulisC, Icons.person_outline),
            const SizedBox(height: 10),
            _dialogField(
              'Stok',
              stokC,
              Icons.inventory_2_outlined,
              type: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isEdit) {
                await supabase
                    .from('books')
                    .update({
                      'judul': judulC.text.trim(),
                      'penulis': penulisC.text.trim(),
                      'stok': int.tryParse(stokC.text.trim()) ?? 0,
                    })
                    .eq('id', book['id']);
              } else {
                await supabase.from('books').insert({
                  'judul': judulC.text.trim(),
                  'penulis': penulisC.text.trim(),
                  'stok': int.tryParse(stokC.text.trim()) ?? 0,
                });
              }
              await _fetchBooks();
              await _fetchStatistik();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Buku diperbarui' : 'Buku ditambahkan',
                    ),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1626),
        title: const Text('Hapus Buku', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus "${book['judul']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await supabase.from('books').delete().eq('id', book['id']);
    await _fetchBooks();
    await _fetchStatistik();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Buku dihapus')));
    }
  }

  TextField _dialogField(
    String label,
    TextEditingController c,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.book_outlined, 'label': 'Buku'},
      {'icon': Icons.history_outlined, 'label': 'Peminjaman'},
      {'icon': Icons.people_outline, 'label': 'Pengguna'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1626),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Navbar Tab
          Container(
            color: const Color(0xFF0E1626),
            child: Row(
              children: List.generate(navItems.length, (i) {
                final selected = _selectedIndex == i;
                final item = navItems[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: selected
                                ? Colors.blueAccent
                                : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.blueAccent
                                  : Colors.white38,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Konten
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildStatistik(),
                _buildKelolaBuku(),
                _buildDataPeminjaman(),
                _buildKelolaPengguna(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Statistik ──
  Widget _buildStatistik() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Perpustakaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statCard('Total Buku', totalBuku, Colors.blue),
              const SizedBox(width: 12),
              _statCard('Total User', totalUser, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Dipinjam', sedangDipinjam, Colors.orange),
              const SizedBox(width: 12),
              _statCard('Dikembalikan', sudahDikembalikan, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Kelola Buku (CRUD) ──
  Widget _buildKelolaBuku() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kelola Buku',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showBookDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loadingBooks
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchBooks,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: books.length,
                    itemBuilder: (_, i) {
                      final book = books[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1626),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            book['judul'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${book['penulis'] ?? '-'} • Stok: ${book['stok'] ?? 0}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                onPressed: () => _showBookDialog(book: book),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _deleteBook(book),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ── Tab 3: Data Peminjaman ──
  Widget _buildDataPeminjaman() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Data Peminjaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: _fetchLoans,
              ),
            ],
          ),
        ),
        Expanded(
          child: loadingLoans
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchLoans,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: loans.length,
                    itemBuilder: (_, i) {
                      final loan = loans[i];
                      final book = loan['books'];
                      final profile = loan['profiles'];
                      final judul = (book is Map) ? book['judul'] ?? '-' : '-';
                      final nama = (profile is Map)
                          ? profile['nama'] ?? '-'
                          : '-';
                      final kelas = (profile is Map)
                          ? profile['kelas'] ?? '-'
                          : '-';
                      final status = loan['status'] ?? '-';
                      final tgl = loan['tanggal_pinjam'] != null
                          ? DateTime.tryParse(loan['tanggal_pinjam'])
                          : null;
                      final tglStr = tgl != null
                          ? '${tgl.day}/${tgl.month}/${tgl.year}'
                          : '-';

                      final isActive = status.toLowerCase() == 'dipinjam';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1626),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            judul,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$nama • $kelas\nTgl: $tglStr',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.orange.withOpacity(0.15)
                                  : Colors.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? Colors.orange : Colors.teal,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isActive ? Colors.orange : Colors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
    );
  }

  // ── Tab 4: Kelola Pengguna ──
  Widget _buildKelolaPengguna() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kelola Pengguna',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: _fetchUsers,
              ),
            ],
          ),
        ),
        Expanded(
          child: loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final user = users[i];
                      final role = user['role'] ?? 'member';
                      final isAdmin = role == 'admin';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1626),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAdmin
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.white12,
                            child: Text(
                              (user['nama'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.blueAccent
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          title: Text(
                            user['nama'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${user['kelas'] ?? '-'} • NISN: ${user['nisn'] ?? '-'}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAdmin
                                    ? Colors.blueAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.blueAccent
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
    );
  }
}
