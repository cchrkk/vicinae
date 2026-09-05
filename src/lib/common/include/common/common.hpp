#pragma once
#include <array>
#include <filesystem>
#include <fstream>
#include <istream>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace vicinae {
inline constexpr std::array<std::string_view, 3> APP_SCHEMES{"vicinae", "raycast", "com.raycast"};

// true for app deeplinks such as vicinae://toggle or com.raycast:/extensions/...
bool isAppDeeplink(std::string_view url);

// Switches the CRT locale to UTF-8 on Windows so that we operate on UTF-8 rather
// than the legacy ANSI code page. No-op elsewhere.
void enableUtf8();

std::filesystem::path selfPath();
std::optional<std::filesystem::path> findHelperProgram(std::string_view program);
std::vector<std::filesystem::path> helperProgramCandidates(std::string_view program);
std::string slurp(std::istream &ifs);

std::optional<std::filesystem::path> findServerBinary();

std::filesystem::path runtimeDir();
std::filesystem::path stateDir();
std::filesystem::path logFilePath();
std::filesystem::path serverSocketPath();

// True when running in portable mode: the executable lives in a writable
// directory (e.g. an extracted zip), so all data must be stored next to the
// binary instead of the per-user AppData / .local locations. Overridable with
// the VICINAE_PORTABLE environment variable (0/1).
bool isPortableMode();

// Base directory used to store data in portable mode. This is the directory
// containing the executable, or its parent when the binary sits in a "bin"
// subdirectory (the layout produced by the portable package).
std::filesystem::path portableRoot();

std::string currentUserName();
std::string serverSocketName();
}; // namespace vicinae
