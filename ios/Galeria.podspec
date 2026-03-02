require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'
new_arch_compiler_flags = '-DRCT_NEW_ARCH_ENABLED'

Pod::Spec.new do |s|
  s.name           = 'Galeria'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platform       = :ios, '16.0'
  s.swift_version  = '5.4'
  s.source         = { git: 'https://github.com/nandorojo/galeria' }
  s.static_framework = true

  s.compiler_flags = new_arch_compiler_flags if new_arch_enabled

  s.dependency 'ExpoModulesCore'
  s.dependency 'SDWebImage'

  # Motion SPM package is added to the main Xcode project by the Expo config
  # plugin (app.plugin.js). The pod finds Motion's built modules via
  # SWIFT_INCLUDE_PATHS pointing at the shared build products directory.
  # See: https://github.com/nandorojo/galeria/issues/110
  spm_checkouts = '${SYMROOT}/../../SourcePackages/checkouts'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'OTHER_SWIFT_FLAGS' => [
      '$(inherited)',
      new_arch_enabled ? new_arch_compiler_flags : '',
      "-Xcc -fmodule-map-file=#{spm_checkouts}/swift-numerics/Sources/_NumericsShims/include/module.modulemap",
    ].reject(&:empty?).join(' '),
    'SWIFT_INCLUDE_PATHS' => [
      '$(inherited)',
      '"${SYMROOT}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}/"',
      "\"#{spm_checkouts}/swift-numerics/Sources/_NumericsShims/include\"",
    ].join(' '),
  }

  s.source_files = "**/*.{h,m,swift}"
end
