const { withXcodeProject } = require('@expo/config-plugins')

/**
 * Expo config plugin that adds the Motion SPM package to the main Xcode project.
 *
 * This replaces the previous `spm_dependency` approach in the podspec, which
 * injected SPM references into Pods.xcodeproj and corrupted it on some Xcode
 * versions (see https://github.com/nandorojo/galeria/issues/110).
 *
 * SPM references work correctly in the main .xcodeproj — the Galeria pod then
 * finds the built Motion module via SWIFT_INCLUDE_PATHS in the podspec.
 */
function withGaleriaMotionSPM(config) {
  return withXcodeProject(config, (config) => {
    const proj = config.modResults
    const objects = proj.hash.project.objects
    const rootProject = objects.PBXProject[proj.hash.project.rootObject]

    const repositoryURL = 'https://github.com/b3ll/Motion.git'
    const productName = 'Motion'

    // Idempotency: skip if already added
    objects.XCRemoteSwiftPackageReference ??= {}
    const alreadyAdded = Object.values(
      objects.XCRemoteSwiftPackageReference
    ).some(
      (ref) => typeof ref === 'object' && ref.repositoryURL === repositoryURL
    )
    if (alreadyAdded) {
      return config
    }

    // Add XCRemoteSwiftPackageReference
    const pkgUUID = proj.generateUuid()
    objects.XCRemoteSwiftPackageReference[pkgUUID] = {
      isa: 'XCRemoteSwiftPackageReference',
      repositoryURL,
      requirement: { kind: 'branch', branch: 'main' },
    }

    // Add to root project's packageReferences
    rootProject.packageReferences ??= []
    rootProject.packageReferences.push({ value: pkgUUID })

    // Find the app target (com.apple.product-type.application)
    const appTargetEntry = Object.entries(objects.PBXNativeTarget).find(
      ([, v]) =>
        typeof v === 'object' &&
        v.productType === '"com.apple.product-type.application"'
    )
    if (!appTargetEntry) {
      return config
    }

    // Add XCSwiftPackageProductDependency
    objects.XCSwiftPackageProductDependency ??= {}
    const depUUID = proj.generateUuid()
    objects.XCSwiftPackageProductDependency[depUUID] = {
      isa: 'XCSwiftPackageProductDependency',
      package: pkgUUID,
      productName,
    }

    // Add to app target's packageProductDependencies
    const appTarget = appTargetEntry[1]
    appTarget.packageProductDependencies ??= []
    appTarget.packageProductDependencies.push({ value: depUUID })

    return config
  })
}

module.exports = withGaleriaMotionSPM
