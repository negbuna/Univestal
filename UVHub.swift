import SwiftUI

struct UVHub: View {
    @State private var newsArticles: [NewsArticle] = [] // will have api data
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("HomeBKG")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VisualEffectBlur(effect: UIBlurEffect(style: .systemMaterial))
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack {
                        Text("Recommended")
                            .foregroundStyle(.primary)
                            .font(.headline)
                            .padding()

                        ForEach(newsArticles) { article in
                            NewsArticleView(article: article)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Hub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UVSettings()) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .onAppear {
            NewsAPI.shared.fetchArticles { articles in
                self.newsArticles = articles
            }
        }
    }
}

struct UVHub_Previews: PreviewProvider {
    @State static private var currentPage = 0 // Example state for preview
    
    static var previews: some View {
        UVHub()
    }
}
