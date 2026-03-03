require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

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

  s.dependency 'ExpoModulesCore'
  s.dependency 'SDWebImage'

  # Let React Native's standard helper configure all new-arch flags & deps.
  if defined?(install_modules_dependencies)
    install_modules_dependencies(s)
  end

  # Motion SPM package is added to the main Xcode project by the Expo config
  # plugin (app.plugin.js). The pod finds Motion's built modules via
  # SWIFT_INCLUDE_PATHS pointing at the shared build products directory.
  # See: https://github.com/nandorojo/galeria/issues/110
  spm_checkouts = '${SYMROOT}/../../SourcePackages/checkouts'

  current_config = s.attributes_hash['pod_target_xcconfig'] || {}

  existing_swift_flags = current_config['OTHER_SWIFT_FLAGS'] || '$(inherited)'
  current_config['OTHER_SWIFT_FLAGS'] = [
    existing_swift_flags,
    "-Xcc -fmodule-map-file=#{spm_checkouts}/swift-numerics/Sources/_NumericsShims/include/module.modulemap",
  ].join(' ')

  current_config['DEFINES_MODULE'] = 'YES'
  current_config['SWIFT_INCLUDE_PATHS'] = [
    '$(inherited)',
    '"${SYMROOT}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}/"',
    "\"#{spm_checkouts}/swift-numerics/Sources/_NumericsShims/include\"",
  ].join(' ')

  s.pod_target_xcconfig = current_config

  s.source_files = "**/*.{h,m,swift}"
end
