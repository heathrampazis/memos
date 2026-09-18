import Foundation
import SwiftUI
import UIKit

/// A snippet in a note.
///
/// The one widget that does not wear the tile's colours. Syntax highlighting
/// that has to stay readable on five different tile palettes ends up readable
/// on none, so the block is a fixed dark ground and the colours are chosen once.
struct CodeWidget: View {
    @Binding var block: CodeBlock
    let color: TileColor
    let session: CodeSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ZStack(alignment: .topLeading) {
                if block.code.isEmpty {
                    Text("Write code…")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(CodeSyntax.gutter))
                        .allowsHitTesting(false)
                }

                CodeEditorView(
                    blockID: block.id,
                    code: $block.code,
                    language: block.language,
                    session: session
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(CodeSyntax.background))
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(CodeLanguage.allCases) { language in
                    Button(language.label) { block.language = language }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(block.language.label)
                        .font(Typography.tileFooter)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .black))
                        .opacity(0.7)
                }
                .foregroundStyle(Color(CodeSyntax.gutter))
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(Capsule().fill(Color(CodeSyntax.plain).opacity(0.08)))
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = block.code
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(CodeSyntax.gutter))
                    .frame(width: 26, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(block.code.isEmpty)
            .opacity(block.code.isEmpty ? 0.4 : 1)
            .accessibilityLabel("Copy code")
        }
    }
}

extension Binding where Value == CodeBlock? {
    func required() -> Binding<CodeBlock> {
        Binding<CodeBlock>(
            get: { self.wrappedValue ?? CodeBlock(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
