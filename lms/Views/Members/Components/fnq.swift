
import SwiftUI
import AVFoundation // For text-to-speech functionality

struct FAQView: View {
    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
        var isExpanded: Bool = false // To track if the dropdown is expanded
        var isAnswerExpanded: Bool = false // To track if the answer is expanded for "View More"
    }

    // Predefined FAQs with initial collapsed state
    @State private var faqs: [FAQItem] = [
        FAQItem(question: "What are the library's operating hours?", answer: "The library is open Monday to Friday from 9:00 AM to 6:00 PM, and on Saturdays from 10:00 AM to 4:00 PM. We are closed on Sundays and public holidays."),
        FAQItem(question: "How do I log in to my library account?", answer: "Visit our app, and click on the 'Login' button. Enter your registered email and the password you set during registration. If you’ve forgotten your password, use the 'Forgot Password' link to reset it. If a new user wants to register then 'Create Account' button is available."),
        FAQItem(question: "How can I update my personal information (e.g., email, phone number)?", answer: "Log in to your account on app, go to 'Profile' button on the 'Home Screen' and update your details. Alternatively, visit the library and request an update at the front desk with proper identification."),
        FAQItem(question: "How many books can I borrow at a time?", answer: "Member can borrow only 1 book at a time. This limit includes any type of material, such as physical books, audiobooks, or other resources, unless specified otherwise."),
        FAQItem(question: "How long can I keep a book?", answer: "The standard loan period is 15 days. You can renew a book for an additional 15 days if there are no holds on it."),
        FAQItem(question: "How do I renew a book?", answer: "To reserve a book, log in to your account and navigate to the 'Explore' screen. Search for the book you wish to reserve, then click on the book to view its metadata. Next, click the 'Reserve Book' button to place your reservation. Once you click the button, your request will be sent to the librarian for approval. After the librarian accepts your request, you can visit the library to issue the book."),
        FAQItem(question: "What happens if I return a book late?", answer: "A late fee of ₹10 per day per book will be charged. You can pay the fine through physically coming at the front desk. Unpaid fines may result in borrowing restrictions."),
        FAQItem(question: "How do I search for a book in the library?", answer: "To view a book’s details, open the app and go to the 'Explore Screen.' Use the search feature to find a book by entering its name. Once you see the book in the search results, click on it to access its metadata, which includes the total number of pages, the year it was released, its genre, ratings, and location within the library."),
        FAQItem(question: "How can I check the status of my reservation requests?", answer: "To check your reservation requests, log in to your account and navigate to the 'Home Screen.' As soon as you reserve a book, your reservation requests will be displayed on the 'Home Screen' for easy access and tracking."),
        FAQItem(question: "How can I check the status of my issued books?", answer: "You can view your issued books on the 'Home Screen' under the 'Currently Reading' section as soon as you issue a book. Additionally, you can find them in the 'My Collection' screen, which includes a 'Borrowed' tab listing all the books you have currently borrowed."),
        FAQItem(question: "How can I check if I have any fines?", answer: "To check for overdue books, go to the 'Home Screen' and navigate to the 'Profile' section. Within the 'Profile' section, you will find an 'Overdues' section where you can view any books that are past their due date.")
    ]

    @State private var searchText: String = ""
    @State private var isSpeaking: Bool = false
    @Environment(\.dismiss) var dismiss

    // Text-to-speech synthesizer
    private let synthesizer = AVSpeechSynthesizer()

    var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter { $0.question.lowercased().contains(searchText.lowercased()) || $0.answer.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Bar with Voice Over Icon
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                        
                        TextField("Search FAQs...", text: $searchText)
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .accessibilityLabel("Search FAQs")
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Button(action: {
                            toggleSpeech()
                        }) {
                            Image(systemName: isSpeaking ? "mic.slash.fill" : "mic.fill")
                                .foregroundColor(isSpeaking ? .red : .blue)
                                .padding(.trailing, 12)
                        }
                        .accessibilityLabel(isSpeaking ? "Stop Voice Over" : "Start Voice Over")
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // FAQ List with Dropdowns
                    ScrollView {
                        VStack(spacing: 12) { // Reduced spacing between FAQ items
                            ForEach($faqs) { $faq in
                                if filteredFAQs.contains(where: { $0.id == faq.id }) {
                                    DisclosureGroup(
                                        isExpanded: $faq.isExpanded
                                    ) {
                                        // Answer Content
                                        let answerPreview = faq.answer.count > 100 && !faq.isAnswerExpanded ? String(faq.answer.prefix(100)) + "..." : faq.answer
                                        
                                        Text(answerPreview)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .padding(.top, 8) // Reduced top padding for answer
                                            .padding(.bottom, 4) // Reduced bottom padding for answer
                                            .accessibilityLabel("Answer: \(faq.answer)")
                                        
                                        if faq.answer.count > 100 {
                                            Button(action: {
                                                faq.isAnswerExpanded.toggle()
                                            }) {
                                                Text(faq.isAnswerExpanded ? "View Less" : "View More")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .padding(.top, 4)
                                            }
                                            .accessibilityLabel(faq.isAnswerExpanded ? "View Less" : "View More")
                                        }
                                    } label: {
                                        Text(faq.question)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(.vertical, 12) // Adjusted vertical padding for question
                                            .accessibilityLabel("Question: \(faq.question)")
                                    }
                                    .padding(.horizontal, 12) // Reduced horizontal padding inside the card
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16) // Adjusted outer padding
                                }
                            }
                            
                            if filteredFAQs.isEmpty {
                                Text("No FAQs found.")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 20)
                                    .accessibilityLabel("No FAQs found.")
                            }
                        }
                        .padding(.top, 4) // Reduced top padding for the list
                        .padding(.bottom, 16) // Added bottom padding for better scroll view spacing
                    }
                }
            }
            .navigationTitle("FAQs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                            Text("Back")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: "FAQ Screen")
        }
        .onDisappear {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
                isSpeaking = false
            }
        }
    }

    private func toggleSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        } else {
            isSpeaking = true
            speakFAQs()
        }
    }

    private func speakFAQs() {
        guard !filteredFAQs.isEmpty else {
            let utterance = AVSpeechUtterance(string: "No FAQs found.")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            synthesizer.speak(utterance)
            return
        }

        for faq in filteredFAQs {
            let text = "Question: \(faq.question). Answer: \(faq.answer)."
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            
            synthesizer.speak(utterance)
            
            let pauseUtterance = AVSpeechUtterance(string: "")
            pauseUtterance.rate = 0.5
            pauseUtterance.preUtteranceDelay = 0.5
            synthesizer.speak(pauseUtterance)
        }
    }
}
