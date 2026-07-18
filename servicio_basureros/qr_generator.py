import qrcode

def generar_etiqueta_basurero(bin_short_id: str):
    # La URL que el usuario escaneará
    url = f"https://ecosmartbin2.web.app/connect?bin={bin_short_id}"

    # Configuración del QR
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H, # Alta corrección (por si se raya o ensucia)
        box_size=10,
        border=4,
    )
    
    qr.add_data(url)
    qr.make(fit=True)

    # Crear la imagen
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Guardar el archivo
    filename = f"QR_Basurero_{bin_short_id}.png"
    img.save(filename)
    print(f"QR generado exitosamente: {filename}")
    print(f"Código manual para imprimir debajo del QR: {bin_short_id}")

# Ejemplo de uso:
generar_etiqueta_basurero("eco01")