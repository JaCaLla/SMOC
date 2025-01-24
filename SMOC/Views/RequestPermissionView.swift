//
//  RequestPermissionView.swift
//  SMOC
//
//  Created by Javier Calatrava on 14/1/25.
//
import SwiftUI


struct RequestPermissionView: View {

    var body: some View {
        VStack(spacing: 20) {
            Image("noGrantedPermissions")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(CornerRadius.regular)
            Text("alert_msg_settinggs")
                .font(.alertMessageFont)
            Button {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "gear")
                    Text("alert_btn_settings")
                        .font(.alertMessageButtonFont)
                        .padding(.horizontal)
                }
                    .padding()
                    .foregroundStyle(Color.buttonTextColor)
                    .background(RoundedRectangle(cornerRadius: CornerRadius.regular))

            }
        }.padding()
    }
}

#Preview {
    RequestPermissionView()
}
