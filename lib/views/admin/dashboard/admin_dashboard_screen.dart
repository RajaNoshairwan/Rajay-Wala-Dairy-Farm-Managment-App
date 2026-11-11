import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../viewmodels/admin_dashboard_viewmodel.dart';
import 'spreadsheet_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _State();
}

class _State extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardViewModel>().load();
  }

  String _fmtKg(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminDashboardViewModel>();

    return vm.loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Overview',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // ── Total Customers (full width) ───────────────
          _WideTile(
            icon: Icons.people,
            color: Colors.blue,
            label: 'Total Customers',
            value: '${vm.totalCustomers}',
          ),
          const SizedBox(height: 16),

          // ── Sales (kg) ─────────────────────────────────
          const _SectionHeader(
              icon: Icons.scale, title: 'Sale (kg)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.today,
                  color: Colors.teal,
                  label: "Today's Sale",
                  value: '${_fmtKg(vm.todaySaleKg)} kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.calendar_month,
                  color: Colors.teal.shade700,
                  label: "This Month's Sale",
                  value: '${_fmtKg(vm.monthSaleKg)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Revenue ────────────────────────────────────
          const _SectionHeader(
              icon: Icons.payments, title: 'Revenue'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  label: "Today's Revenue",
                  value: CurrencyFormatter.format(vm.todayRevenue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  label: "This Month's Revenue",
                  value: CurrencyFormatter.format(vm.monthRevenue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Profit ─────────────────────────────────────
          const _SectionHeader(
              icon: Icons.savings, title: 'Profit'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.today,
                  color: AppColors.accent,
                  label: "Today's Profit",
                  value: CurrencyFormatter.format(vm.todayProfit),
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.calendar_month,
                  color: AppColors.accent,
                  label: "This Month's Profit",
                  value: CurrencyFormatter.format(vm.monthProfit),
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Profit = Revenue − Rs. ${AdminDashboardViewModel.costPerKg.toStringAsFixed(0)} per kg cost',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // ── Spreadsheet shortcut (unchanged) ──────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.table_chart,
                  color: AppColors.primary, size: 32),
              title: const Text('Monthly Spreadsheet',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  'All customers × days grid · Edit in place · Copy from previous day'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SpreadsheetScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Wide tile (full-width)
// ─────────────────────────────────────────────────────────────
class _WideTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _WideTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Square tile (half-width)
// ─────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool highlight;

  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: color.withValues(alpha: 0.25), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}