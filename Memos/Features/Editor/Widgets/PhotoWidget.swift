import Foundation
import PhotosUI
import SwiftUI
import UIKit

// A picture, as wide as the note allows and no wider.
struct PhotoWidget: View {
    @Binding var photo: PhotoBlock
    let color: TileColor

    @State private var image: UIImage?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            content
        }
        .buttonStyle(.plain)
        .onChange(of: selection) { _, item in adopt(item) }
        .onAppear { image = PhotoStore.load(photo.id) }
        .onChange(of: photo.revision) { image = PhotoStore.load(photo.id) }
    }

    @ViewBuilder
    private var content: some View {
        if photo.isEmpty {
            VStack(spacing: 7) {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .semibold))
                Text("Choose a photo")
                    .font(Typography.barLabel)
            }
            .foregroundStyle(color.inkTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.ink.opacity(0.10))
            )
        } else {
            // The shape is held from the stored size rather than the loaded
            // image, so the note does not jump as pictures come in.
            Color.clear
                .aspectRatio(photo.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(color.ink.opacity(0.10))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func adopt(_ item: PhotosPickerItem?) {
        guard let item else { return }
        let id = photo.id

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            guard let size = await Task.detached(priority: .userInitiated, operation: {
                PhotoStore.write(data, id: id)
            }).value else { return }

            image = PhotoStore.load(id)
            // A zero height would divide by zero, so an unmeasured image stays square.
            if size.height > 0 {
                photo.aspectRatio = size.width / size.height
            } else {
                photo.aspectRatio = 1
            }
            photo.isEmpty = false
            photo.revision += 1
            selection = nil
        }
    }
}

extension Binding where Value == PhotoBlock? {
    func required() -> Binding<PhotoBlock> {
        Binding<PhotoBlock>(
            get: { self.wrappedValue ?? PhotoBlock(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
