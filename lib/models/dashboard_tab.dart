/// Ein geöffneter Projekt-Dashboard-Tab (lokale `index.html`).
class DashboardTab {
  const DashboardTab({
    required this.projectName,
    required this.projectDir,
    required this.indexPath,
  });

  final String projectName;
  final String projectDir;
  final String indexPath;

  String get id => indexPath;
}
