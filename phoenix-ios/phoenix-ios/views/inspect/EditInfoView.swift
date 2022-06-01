import SwiftUI
import PhoenixShared
import os.log

#if DEBUG && false
fileprivate var log = Logger(
	subsystem: Bundle.main.bundleIdentifier!,
	category: "EditInfoView"
)
#else
fileprivate var log = Logger(OSLog.disabled)
#endif


struct EditInfoView: View, ViewName {
	
	@Binding var paymentInfo: WalletPaymentInfo
	
	let defaultDescText: String
	let originalDescText: String?
	@State var descText: String
	
	let maxDescCount: Int = 64
	@State var remainingDescCount: Int
	
	let originalNotesText: String?
	@State var notesText: String
	
	let maxNotesCount: Int = 280
	@State var remainingNotesCount: Int
	
	@State var hasChanges = false
	
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	
	init(paymentInfo: Binding<WalletPaymentInfo>) {
		_paymentInfo = paymentInfo
		
		let pi = paymentInfo.wrappedValue
		
		defaultDescText = pi.paymentDescription(includingUserDescription: false) ?? ""
		let realizedDesc = pi.paymentDescription(includingUserDescription: true) ?? ""
		
		if realizedDesc == defaultDescText {
			originalDescText = nil
			_descText = State(initialValue: "")
			_remainingDescCount = State(initialValue: maxDescCount)
		} else {
			originalDescText = realizedDesc
			_descText = State(initialValue: realizedDesc)
			_remainingDescCount = State(initialValue: maxDescCount - realizedDesc.count)
		}
		
		originalNotesText = pi.metadata.userNotes
		let notes = pi.metadata.userNotes ?? ""
		
		_notesText = State(initialValue: notes)
		_remainingNotesCount = State(initialValue: maxNotesCount - notes.count)
	}
	
	@ViewBuilder
	var body: some View {
		
		VStack(alignment: HorizontalAlignment.center, spacing: 0) {
			
			HStack(alignment: VerticalAlignment.center, spacing: 0) {
				Button {
					saveButtonTapped()
				} label: {
					HStack(alignment: .center, spacing: 4) {
						Image(systemName: "chevron.backward")
							.imageScale(.medium)
						Text("Save")
					}
				}
				Spacer()
			}
			.font(.title3)
			.padding()
			
			ScrollView {
				content
			}
		}
		.navigationBarTitle(
			NSLocalizedString("Edit Info", comment: "Navigation bar title"),
			displayMode: .inline
		)
		.navigationBarHidden(true)
	}
	
	@ViewBuilder
	var content: some View {
		
		VStack(alignment: HorizontalAlignment.leading, spacing: 0) {
			
			Text("Description:")
				.padding(.leading, 8)
				.padding(.bottom, 4)
			
			HStack(alignment: VerticalAlignment.center, spacing: 0) {
				TextField(defaultDescText, text: $descText)
				
				// Clear button (appears when TextField's text is non-empty)
				Button {
					descText = ""
				} label: {
					Image(systemName: "multiply.circle.fill")
						.foregroundColor(.secondary)
				}
				.isHidden(descText == "")
			}
			.padding(.all, 8)
			.overlay(
				RoundedRectangle(cornerRadius: 8)
					.stroke(Color.textFieldBorder, lineWidth: 1)
			)
			
			HStack(alignment: VerticalAlignment.center, spacing: 0) {
				Spacer()
				
				Text("\(remainingDescCount) remaining")
					.font(.callout)
					.foregroundColor(remainingDescCount >= 0 ? Color.secondary : Color.appNegative)
			}
			.padding([.leading, .trailing], 8)
			.padding(.top, 4)
			
			Text("Notes:")
				.padding(.top, 20)
				.padding(.leading, 8)
				.padding(.bottom, 4)
				
			TextEditor(text: $notesText)
				.frame(minHeight: 80, maxHeight: 320)
				.padding(.all, 8)
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(Color.textFieldBorder, lineWidth: 1)
				)
			
			HStack(alignment: VerticalAlignment.center, spacing: 0) {
				Spacer()
				
				Text("\(remainingNotesCount) remaining")
					.font(.callout)
					.foregroundColor(remainingNotesCount >= 0 ? Color.secondary : Color.appNegative)
			}
			.padding([.leading, .trailing], 8)
			.padding(.top, 4)
			
			Button {
				discardButtonTapped()
			} label: {
				Text("Discard Changes")
			}
			.disabled(!hasChanges)
			.padding(.top, 8)
		}
		.padding(.top)
		.padding([.leading, .trailing])
		.onChange(of: descText) {
			descTextDidChange($0)
		}
		.onChange(of: notesText) {
			notesTextDidChange($0)
		}
	}
	
	func descTextDidChange(_ newText: String) {
		log.trace("[\(viewName)] descTextDidChange()")
		
		remainingDescCount = maxDescCount - newText.count
		updateHasChanges()
	}
	
	func notesTextDidChange(_ newText: String) {
		log.trace("[\(viewName)] notesTextDidChange()")
		
		remainingNotesCount = maxNotesCount - newText.count
		updateHasChanges()
	}
	
	func updateHasChanges() {
		
		hasChanges =
			descText != (originalDescText ?? "") ||
			notesText != (originalNotesText ?? "")
	}
	
	func discardButtonTapped() {
		log.trace("[\(viewName)] discardButtonTapped()")
		
		let realizedDesc = originalDescText ?? ""
		if realizedDesc == defaultDescText {
			descText = ""
			remainingDescCount = maxDescCount
		} else {
			descText = realizedDesc
			remainingDescCount = maxDescCount - realizedDesc.count
		}
		
		let realizedNotes = originalNotesText ?? ""
		notesText = realizedNotes
		remainingNotesCount = maxNotesCount - realizedNotes.count
	}
	
	func saveButtonTapped() {
		log.trace("[\(viewName)] saveButtonTapped()")
		
		let paymentId = paymentInfo.id()
		var desc = descText.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if desc.count > maxDescCount {
			let endIdx = desc.index(desc.startIndex, offsetBy: maxDescCount)
			let substr = desc[desc.startIndex ..< endIdx]
			desc = String(substr)
		}
		
		let newDesc = (desc == defaultDescText) ? nil : (desc.count == 0 ? nil : desc)
		
		var notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if notes.count > maxNotesCount {
			let endIdx = notes.index(notes.startIndex, offsetBy: maxNotesCount)
			let substr = notes[notes.startIndex ..< endIdx]
			notes = String(substr)
		}
		
		let newNotes = notes.count == 0 ? nil : notes
		
		if (originalDescText != newDesc) || (originalNotesText != newNotes) {
		
			let business = AppDelegate.get().business
			business.databaseManager.paymentsDb { (paymentsDb: SqlitePaymentsDb?, _) in
				
				paymentsDb?.updateMetadata(id: paymentId, userDescription: newDesc, userNotes: newNotes) { (_, err) in
					
					if let err = err {
						log.error("paymentsDb.updateMetadata: \(String(describing: err))")
					}
				}
			}
		} else {
			log.debug("[\(viewName)] no changes - nothing to save")
		}
		
		presentationMode.wrappedValue.dismiss()
	}
}
