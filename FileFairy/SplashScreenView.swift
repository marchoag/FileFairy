import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           center: .center,
                           startRadius: 100,
                           endRadius: 350)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "wand.and.stars.inverse")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 170, height: 170)
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                
                VStack(spacing: 10) {
                    Text("FileFairy*")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    
                    Text("Rename your exported Apple Photos folders chronologically.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text ("Copyright © 2024 Marc Hoag. All Rights Reserved.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1 : 0)
            }
            .frame(width: 350, height: 450) // Increased width and height
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.2))
                    .blur(radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the entire available space
        .background(
            RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           center: .center,
                           startRadius: 100,
                           endRadius: 350)
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
