/// Locations passed in by demo/tool/render.sh.
abstract final class FilmPaths {
  /// The demo/ directory of this repo.
  static const root = String.fromEnvironment('FILM_ROOT');

  /// Where rendered clips and their sidecars go, outside git.
  static const out = String.fromEnvironment('FILM_OUT');
}
