import SwiftUI
import PDFKit

struct PDFReaderView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Premium Configuration
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Accessibility Support
        // PDFView natively supports VoiceOver for text within the PDF
        pdfView.accessibilityLabel = "Digital Book Content"
        pdfView.isAccessibilityElement = false // The subviews (pages) are elements
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Handle updates if needed
    }
}

// A wrapper that adds accessibility controls
struct AccessiblePDFReader: View {
    let url: URL
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 0) {
            PDFReaderView(url: url)
                .edgesIgnoringSafeArea(.all)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("E-Book Reader")
        .accessibilityHint("Use two fingers to scroll through pages. VoiceOver will read the text automatically.")
    }
}
