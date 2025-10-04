import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/service_request.dart';
import '../../services/service_request_service.dart';

class ServiceRequestsView extends StatefulWidget {
  const ServiceRequestsView({super.key});

  @override
  State<ServiceRequestsView> createState() => _ServiceRequestsViewState();
}

class _ServiceRequestsViewState extends State<ServiceRequestsView> {
  final ServiceRequestService _serviceRequestService = ServiceRequestService();
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;
  ServiceRequestStatus? _selectedFilter;

  final Map<ServiceRequestStatus?, String> _statusFilters = {
    null: 'All Requests',
    ServiceRequestStatus.pending: 'Pending',
    ServiceRequestStatus.confirmed: 'Confirmed',
    ServiceRequestStatus.scheduled: 'Scheduled',
    ServiceRequestStatus.completed: 'Completed',
  };

  final Map<ServiceRequestStatus, Color> _statusColors = {
    ServiceRequestStatus.pending: Colors.orange,
    ServiceRequestStatus.confirmed: Colors.blue,
    ServiceRequestStatus.scheduled: Colors.purple,
    ServiceRequestStatus.completed: Colors.green,
    ServiceRequestStatus.inProgress: Colors.amber,
    ServiceRequestStatus.cancelled: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _serviceRequestService.getAllServiceRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  List<ServiceRequest> get _filteredRequests {
    if (_selectedFilter == null) {
      return _requests;
    }
    return _requests.where((request) => request.status == _selectedFilter).toList();
  }

  Future<void> _updateRequestStatus(String requestId, ServiceRequestStatus newStatus) async {
    try {
      // TODO: Implement updateServiceRequestStatus in service
      // await _serviceRequestService.updateServiceRequestStatus(requestId, newStatus);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request status updated to ${newStatus.displayName}'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Wrap(
            spacing: 8,
            children: _statusFilters.entries.map((entry) {
              final isSelected = _selectedFilter == entry.key;
              return FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = entry.key;
                  });
                },
                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryTeal,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No service requests found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${request.userId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColors[request.status]?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _statusColors[request.status] ?? Colors.grey,
                    ),
                  ),
                  child: Text(
                    request.status.displayName.toUpperCase(),
                    style: TextStyle(
                      color: _statusColors[request.status] ?? Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.displayAddress,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (request.status == ServiceRequestStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateRequestStatus(request.id, ServiceRequestStatus.confirmed),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateRequestStatus(request.id, ServiceRequestStatus.scheduled),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (request.status == ServiceRequestStatus.scheduled) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateRequestStatus(request.id, ServiceRequestStatus.completed),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}