import SwiftUI
import CoreImage.CIFilterBuiltins

struct BarcodeDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    let isbn: String
    let onScanRequested: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Barcode Card
                    VStack(spacing: 24) {
                        Text("BOOK BARCODE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.textSecondary)
                            .tracking(2)
                        
                        if let image = generateBarcode(from: isbn) {
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.none) // Keep lines sharp
                                .scaledToFit()
                                .frame(height: 120)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "barcode")
                                    .font(.system(size: 60))
                                    .foregroundColor(.purple.opacity(0.3))
                                Text("No ISBN Available")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        Text(isbn.isEmpty ? "---- ---- ----" : isbn)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(32)
                    .background(Color.cardBg)
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 12)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            dismiss()
                            onScanRequested()
                        }) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Scan New Barcode")
                            }
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Dismiss")
                                .font(.headline)
                                .foregroundColor(.textSecondary)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Barcode Identifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.purple)
                        .font(.headline)
                }
            }
        }
    }
    
    private func generateBarcode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }
        
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            // Code 128 generator returns a sharp image, but it's small.
            // We scale it up using a transform.
            let transform = CGAffineTransform(scaleX: 5, y: 5)
            
            if let outputImage = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}
