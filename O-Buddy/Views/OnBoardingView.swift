import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pageCount = 5

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#B1FCFF"), .white]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                    OnboardingPage4().tag(3)
                    OnboardingPage5().tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                Spacer()

                CustomPageIndicator(currentPage: currentPage, pageCount: pageCount)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OBD II")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OBD II")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OBD II")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OBD II")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage5: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("OBD II")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)

            Text("This app requires an OBD II interface to work.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



struct CustomPageIndicator: View {
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(height: 10)
                .cornerRadius(5)

            HStack(spacing: 32) {
                ForEach(0..<pageCount, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 36, height: 36)

                        if index == currentPage {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 40)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    OnboardingView()
}
