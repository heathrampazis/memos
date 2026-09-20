import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Appearance") {
                        Picker("Appearance", selection: $settings.appearance) {
                            ForEach(Appearance.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    section("Tile palette") {
                        VStack(spacing: 10) {
                            ForEach(TilePaletteKind.allCases) { kind in
                                paletteRow(kind, isSelected: settings.palette == kind)
                            }
                        }
                    }

                    // App Review wants the privacy policy reachable from inside
                    // the app, not only from the store listing.
                    section("Legal") {
                        VStack(spacing: 10) {
                            linkRow("Privacy policy", Legal.privacyPolicy)
                            linkRow("Terms of use", Legal.terms)
                            linkRow("Support", Legal.support)
                        }
                    }

                    Text(Legal.version)
                        .font(Typography.sheetCaption)
                        .foregroundStyle(settings.panelInk.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(Spacing.screen)
            }
            .background(settings.panel)
            .toolbarBackground(settings.panel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Typography.barLabel)
                        .foregroundStyle(settings.panelInk)
                }
            }
        }
        .presentationBackground(settings.panel)
        .preferredColorScheme(settings.appearance.colorScheme)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(Typography.sectionLabel)
                .kerning(0.8)
                .foregroundStyle(settings.panelInk.opacity(0.55))
            content()
        }
    }

    private func linkRow(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Text(title)
                    .font(Typography.rowTitle)
                    .foregroundStyle(settings.panelInk)

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(settings.panelInk.opacity(0.45))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(settings.panelSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(settings.panelInk.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func paletteRow(_ kind: TilePaletteKind, isSelected: Bool) -> some View {
        Button {
            settings.palette = kind
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.label)
                        .font(Typography.rowTitle)
                        .foregroundStyle(settings.panelInk)
                    Text(kind.caption)
                        .font(Typography.sheetCaption)
                        .foregroundStyle(settings.panelInk.opacity(0.62))
                }

                Spacer(minLength: 0)

                HStack(spacing: 3) {
                    ForEach(TilePalettes.colors(for: kind)) { color in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(color.fill)
                            .frame(width: 10, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .strokeBorder(settings.panelInk.opacity(0.14), lineWidth: 0.5)
                            )
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(isSelected ? settings.panelInk : settings.panelInk.opacity(0.22))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(settings.panelSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? settings.panelInk : settings.panelInk.opacity(0.16),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
