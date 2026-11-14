import os
import uuid

def get_id(key):
    return uuid.uuid5(uuid.NAMESPACE_DNS, f"wavemix.{key}").hex[:24].upper()

app_swift_files = []
for root, _, files in os.walk('WaveMix'):
    for f in files:
        if f.endswith('.swift'):
            # Path relative to WaveMix group folder
            rel_in_group = os.path.relpath(os.path.join(root, f), 'WaveMix').replace('\\', '/')
            app_swift_files.append((f, rel_in_group))

test_swift_files = []
for root, _, files in os.walk('WaveMixTests'):
    for f in files:
        if f.endswith('.swift'):
            # Path relative to WaveMixTests group folder
            rel_in_group = os.path.relpath(os.path.join(root, f), 'WaveMixTests').replace('\\', '/')
            test_swift_files.append((f, rel_in_group))

resource_files = [
    ('Assets.xcassets', 'Resources/Assets.xcassets'),
    ('PrivacyInfo.xcprivacy', 'Resources/PrivacyManifest/PrivacyInfo.xcprivacy'),
    ('Info.plist', 'Resources/Info.plist'),
    ('WaveMix.entitlements', 'Resources/WaveMix.entitlements')
]

lines = ['// !$*UTF8*$!', '{', '\tarchiveVersion = 1;', '\tclasses = {', '\t};', '\tobjectVersion = 56;', '\tobjects = {']

# 1. PBXBuildFile
lines.append('\n/* Begin PBXBuildFile section */')
for f, path in app_swift_files:
    lines.append(f'\t\t{get_id("build_" + path)} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {get_id("ref_" + path)} /* {f} */; }};')

for f, path in test_swift_files:
    lines.append(f'\t\t{get_id("build_" + path)} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {get_id("ref_" + path)} /* {f} */; }};')

for f, path in resource_files:
    if f.endswith('.xcassets') or f.endswith('.xcprivacy'):
        lines.append(f'\t\t{get_id("build_" + path)} /* {f} in Resources */ = {{isa = PBXBuildFile; fileRef = {get_id("ref_" + path)} /* {f} */; }};')
lines.append('/* End PBXBuildFile section */')

# 2. PBXFileReference
lines.append('\n/* Begin PBXFileReference section */')
lines.append(f'\t\t{get_id("product_app")} /* WaveMix.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WaveMix.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append(f'\t\t{get_id("product_tests")} /* WaveMixTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = WaveMixTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')

for f, path in app_swift_files:
    lines.append(f'\t\t{get_id("ref_" + path)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = "<group>"; }};')

for f, path in test_swift_files:
    lines.append(f'\t\t{get_id("ref_" + path)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = "<group>"; }};')

for f, path in resource_files:
    if f.endswith('.xcassets'):
        file_type = 'folder.assetcatalog'
    elif f.endswith('.plist') or f.endswith('.xcprivacy') or f.endswith('.entitlements'):
        file_type = 'text.plist.xml'
    else:
        file_type = 'text'
    lines.append(f'\t\t{get_id("ref_" + path)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{path}"; sourceTree = "<group>"; }};')
lines.append('/* End PBXFileReference section */')

# 3. PBXFrameworksBuildPhase
lines.append('\n/* Begin PBXFrameworksBuildPhase section */')
lines.append(f'\t\t{get_id("frameworks_app")} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};')
lines.append(f'\t\t{get_id("frameworks_tests")} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};')
lines.append('/* End PBXFrameworksBuildPhase section */')

# 4. PBXGroup
lines.append('\n/* Begin PBXGroup section */')
lines.append(f'\t\t{get_id("main_group")} = {{isa = PBXGroup; children = ({get_id("wavemix_group")}, {get_id("tests_group")}, {get_id("products_group")}); sourceTree = "<group>"; }};')
lines.append(f'\t\t{get_id("products_group")} /* Products */ = {{isa = PBXGroup; children = ({get_id("product_app")}, {get_id("product_tests")}); name = Products; sourceTree = "<group>"; }};')

app_refs = ', '.join([f'{get_id("ref_" + p)} /* {f} */' for f, p in app_swift_files + resource_files])
lines.append(f'\t\t{get_id("wavemix_group")} /* WaveMix */ = {{isa = PBXGroup; children = ({app_refs}); path = WaveMix; sourceTree = "<group>"; }};')

test_refs = ', '.join([f'{get_id("ref_" + p)} /* {f} */' for f, p in test_swift_files])
lines.append(f'\t\t{get_id("tests_group")} /* WaveMixTests */ = {{isa = PBXGroup; children = ({test_refs}); path = WaveMixTests; sourceTree = "<group>"; }};')
lines.append('/* End PBXGroup section */')

# 5. PBXNativeTarget
lines.append('\n/* Begin PBXNativeTarget section */')
lines.append(f'''\t\t{get_id("target_app")} /* WaveMix */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {get_id("config_list_app")};
\t\t\tbuildPhases = (
\t\t\t\t{get_id("sources_app")},
\t\t\t\t{get_id("frameworks_app")},
\t\t\t\t{get_id("resources_app")}
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = WaveMix;
\t\t\tproductName = WaveMix;
\t\t\tproductReference = {get_id("product_app")};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};''')

lines.append(f'''\t\t{get_id("target_tests")} /* WaveMixTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {get_id("config_list_tests")};
\t\t\tbuildPhases = (
\t\t\t\t{get_id("sources_tests")},
\t\t\t\t{get_id("frameworks_tests")}
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{get_id("dependency_app")}
\t\t\t);
\t\t\tname = WaveMixTests;
\t\t\tproductName = WaveMixTests;
\t\t\tproductReference = {get_id("product_tests")};
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};''')
lines.append('/* End PBXNativeTarget section */')

# 6. PBXProject
lines.append('\n/* Begin PBXProject section */')
lines.append(f'''\t\t{get_id("project")} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1520;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{get_id("target_app")} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.2;
\t\t\t\t\t}};
\t\t\t\t\t{get_id("target_tests")} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.2;
\t\t\t\t\t\tTestTargetID = {get_id("target_app")};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {get_id("config_list_project")};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {get_id("main_group")};
\t\t\tproductRefGroup = {get_id("products_group")};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{get_id("target_app")},
\t\t\t\t{get_id("target_tests")}
\t\t\t);
\t\t}};''')
lines.append('/* End PBXProject section */')

# 7. PBXResourcesBuildPhase
lines.append('\n/* Begin PBXResourcesBuildPhase section */')
res_build_refs = ', '.join([f'{get_id("build_" + p)}' for f, p in resource_files if f.endswith('.xcassets') or f.endswith('.xcprivacy')])
lines.append(f'\t\t{get_id("resources_app")} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({res_build_refs}); runOnlyForDeploymentPostprocessing = 0; }};')
lines.append('/* End PBXResourcesBuildPhase section */')

# 8. PBXSourcesBuildPhase
lines.append('\n/* Begin PBXSourcesBuildPhase section */')
app_sources = ', '.join([f'{get_id("build_" + p)}' for f, p in app_swift_files])
lines.append(f'\t\t{get_id("sources_app")} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({app_sources}); runOnlyForDeploymentPostprocessing = 0; }};')

test_sources = ', '.join([f'{get_id("build_" + p)}' for f, p in test_swift_files])
lines.append(f'\t\t{get_id("sources_tests")} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({test_sources}); runOnlyForDeploymentPostprocessing = 0; }};')
lines.append('/* End PBXSourcesBuildPhase section */')

# 9. PBXTargetDependency & ContainerItemProxy
lines.append('\n/* Begin PBXTargetDependency section */')
lines.append(f'''\t\t{get_id("dependency_app")} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {get_id("target_app")};
\t\t\ttargetProxy = {get_id("proxy_app")};
\t\t}};''')
lines.append('/* End PBXTargetDependency section */')

lines.append('\n/* Begin PBXContainerItemProxy section */')
lines.append(f'''\t\t{get_id("proxy_app")} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {get_id("project")};
\t\t\tproxyType = 1;
\t\t\tremotedGlobalIDString = {get_id("target_app")};
\t\t\tremoteInfo = WaveMix;
\t\t}};''')
lines.append('/* End PBXContainerItemProxy section */')

# 10. XCBuildConfiguration & XCConfigurationList
lines.append('\n/* Begin XCBuildConfiguration section */')
# Project configurations
lines.append(f'''\t\t{get_id("proj_debug")} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};''')

lines.append(f'''\t\t{get_id("proj_release")} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};''')

# Target App configurations
lines.append(f'''\t\t{get_id("app_debug")} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Resources/WaveMix.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Resources/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wavemix.musicplayer;
\t\t\t\tPRODUCT_NAME = WaveMix;
\t\t\t\tPRODUCT_MODULE_NAME = WaveMix;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};''')

lines.append(f'''\t\t{get_id("app_release")} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Resources/WaveMix.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Resources/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wavemix.musicplayer;
\t\t\t\tPRODUCT_NAME = WaveMix;
\t\t\t\tPRODUCT_MODULE_NAME = WaveMix;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};''')

# Target Tests configurations
lines.append(f'''\t\t{get_id("tests_debug")} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wavemix.musicplayerTests;
\t\t\t\tPRODUCT_NAME = WaveMixTests;
\t\t\t\tPRODUCT_MODULE_NAME = WaveMixTests;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/WaveMix.app/WaveMix";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};''')

lines.append(f'''\t\t{get_id("tests_release")} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wavemix.musicplayerTests;
\t\t\t\tPRODUCT_NAME = WaveMixTests;
\t\t\t\tPRODUCT_MODULE_NAME = WaveMixTests;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/WaveMix.app/WaveMix";
\t\t\t}};
\t\t\tname = Release;
\t\t}};''')
lines.append('/* End XCBuildConfiguration section */')

# 11. XCConfigurationList
lines.append('\n/* Begin XCConfigurationList section */')
lines.append(f'''\t\t{get_id("config_list_project")} /* Build configuration list for PBXProject */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{get_id("proj_debug")},
\t\t\t\t{get_id("proj_release")}
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};''')

lines.append(f'''\t\t{get_id("config_list_app")} /* Build configuration list for PBXNativeTarget "WaveMix" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{get_id("app_debug")},
\t\t\t\t{get_id("app_release")}
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};''')

lines.append(f'''\t\t{get_id("config_list_tests")} /* Build configuration list for PBXNativeTarget "WaveMixTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{get_id("tests_debug")},
\t\t\t\t{get_id("tests_release")}
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};''')
lines.append('/* End XCConfigurationList section */')

lines.append('\t};')
lines.append(f'\trootObject = {get_id("project")} /* Project object */;')
lines.append('}')

content = '\n'.join(lines)
os.makedirs('WaveMix.xcodeproj', exist_ok=True)
with open('WaveMix.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"WaveMix.xcodeproj/project.pbxproj generated successfully ({len(content)} bytes).")

# 12. Create shared schemes
shared_schemes_dir = 'WaveMix.xcodeproj/xcshareddata/xcschemes'
os.makedirs(shared_schemes_dir, exist_ok=True)

app_target_id = get_id("target_app")
tests_target_id = get_id("target_tests")

scheme_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1520"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "WaveMix.app"
               BlueprintName = "WaveMix"
               ReferencedContainer = "container:WaveMix.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{tests_target_id}"
               BuildableName = "WaveMixTests.xctest"
               BlueprintName = "WaveMixTests"
               ReferencedContainer = "container:WaveMix.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{tests_target_id}"
               BuildableName = "WaveMixTests.xctest"
               BlueprintName = "WaveMixTests"
               ReferencedContainer = "container:WaveMix.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "WaveMix.app"
            BlueprintName = "WaveMix"
            ReferencedContainer = "container:WaveMix.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''

with open(os.path.join(shared_schemes_dir, 'WaveMix.xcscheme'), 'w', encoding='utf-8') as f:
    f.write(scheme_content)

tests_scheme_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1520"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{tests_target_id}"
               BuildableName = "WaveMixTests.xctest"
               BlueprintName = "WaveMixTests"
               ReferencedContainer = "container:WaveMix.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{tests_target_id}"
               BuildableName = "WaveMixTests.xctest"
               BlueprintName = "WaveMixTests"
               ReferencedContainer = "container:WaveMix.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
</Scheme>
'''

with open(os.path.join(shared_schemes_dir, 'WaveMixTests.xcscheme'), 'w', encoding='utf-8') as f:
    f.write(tests_scheme_content)

print(f"Generated shared schemes: WaveMix.xcscheme, WaveMixTests.xcscheme")
