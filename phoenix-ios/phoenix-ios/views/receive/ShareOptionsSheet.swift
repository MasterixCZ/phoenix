import SwiftUI

/// Sheet content with buttons:
///
/// Share Text (Lightning invoice)
/// Share Image (QR code)
///
struct ShareOptionsSheet: View {
	
	let shareText: () -> Void
	let shareImage: () -> Void
	
	@Environment(\.shortSheetState) var shortSheetState: ShortSheetState
	
	@ViewBuilder
	var body: some View {
		
		VStack {
			
			Button {
				shortSheetState.close {
					shareText()
				}
			} label: {
				HStack(alignment: VerticalAlignment.firstTextBaseline, spacing: 4) {
					Image(systemName: "square.and.arrow.up")
						.imageScale(.medium)
					Text("Share Text")
					Spacer()
					Text("(Lightning invoice)")
						.font(.footnote)
						.foregroundColor(.secondary)
				}
				.padding([.top, .bottom], 8)
				.padding([.leading, .trailing], 16)
				.contentShape(Rectangle()) // make Spacer area tappable
			}
			.buttonStyle(
				ScaleButtonStyle(
					borderStroke: Color.appAccent
				)
			)
			.padding(.bottom, 8)
			
			Button {
				shortSheetState.close {
					shareImage()
				}
			} label: {
				HStack(alignment: VerticalAlignment.firstTextBaseline, spacing: 4) {
					Image(systemName: "square.and.arrow.up")
						.imageScale(.medium)
					Text("Share Image")
					Spacer()
					Text("(QR code)")
						.font(.footnote)
						.foregroundColor(.secondary)
				}
				.padding([.top, .bottom], 8)
				.padding([.leading, .trailing], 16)
				.contentShape(Rectangle()) // make Spacer area tappable
			}
			.buttonStyle(
				ScaleButtonStyle(
					borderStroke: Color.appAccent
				)
			)
		}
		.padding(.all)
	}
}
