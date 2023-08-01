<img align="left" width="100" height="100" src="https://user-images.githubusercontent.com/9553519/80646366-3d271680-8a75-11ea-8b60-9c5edd4ffd60.png">

# iTorrent - Aplicación cliente Torrent para iOS
**Este archivo Readme podría no estar actualizado, considere revisar el Readme en [**ingles**](README.md)**

![](https://img.shields.io/badge/iOS-9.3+-blue.svg)
![](https://app.bitrise.io/app/26ce0756a727335c/status.svg?token=BLhjBICoPvmOtO1nzIVMYQ&branch=master)
[![](https://build.appcenter.ms/v0.1/apps/a9efbde4-560e-438a-a178-b17563f9c2da/branches/Dev/badge)](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public)

## Capturas de pantalla
<details>
<summary>iPhone Screenshots</summary>
  
![iPhone screenshots](https://user-images.githubusercontent.com/9553519/80644526-7316cb80-8a72-11ea-95b5-e63531d81f35.png)

</details>
<details>
<summary>iPad Screenshots</summary>

![iPad screenshots](https://user-images.githubusercontent.com/9553519/80646848-27feb780-8a76-11ea-8c91-f76d25c0b862.png)

</details>

## Descargar

**Última versión estable:** ([GitHub Release](https://github.com/XITRIX/iTorrent/releases/latest))

**Última versión de desarrollo:** ([AppCenter](https://install.appcenter.ms/users/x1trix/apps/itorrent/distribution_groups/public))

## Información

Se trata de un cliente torrent normal y corriente para iOS compatible con la aplicación Archivos.

Qué puede hacer esta aplicación:

- Descarga en segundo plano
- Descarga secuencial (usa VLC para ver películas mientras se cargan)
- Añadir archivos torrent desde el menú Compartir (Safari y otras aplicaciones)
- Añadir enlaces magnet directamente desde Safari
- Almacenar archivos en la app Archivos (iOS 11+)
- Compartir archivos directamente desde la app
- Descargar torrent por enlace
- Descargar torrent por un enlace magnet
- Enviar notificación de descarga de torrent
- Servidor WebDav
- Seleccionar archivos para descargar o no
- Cambiar la interfaz de usuario a un tema oscuro
- Fuente RSS
- ??? 

## Localización

Ahora iTorrent soporta los siguientes idiomas:
- Inglés
- Ruso
- Turco
- Español

Si domina alguna de las lenguas que no figuran en la lista anterior y desea colaborar en la traducción, ¡será bienvenido!

## Construir

Para construir ese proyecto necesitas tener Cocoapods instalado

Pasos a seguir:
- cd terminal a la carpeta del proyecto "cd /home/usuario/iTorrent"
- Construir pods "pod install"
- Abrir .xcworkspace y construirlo
- Beneficio

## Bibliotecas utilizadas

- [LibTorrent](https://github.com/arvidn/libtorrent)
- [BackgroundTask](https://github.com/yarodevuci/backgroundTask)
- [SwiftyXMLParser](https://github.com/yahoojapan/SwiftyXMLParser)
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
- [DeepDiff](https://github.com/onmyway133/DeepDiff)

## Donaciones para donuts

- [Patreon](https://www.patreon.com/xitrix)
- [PayPal](https://paypal.me/xitrix)

## Información importante

Esta aplicación utiliza Firebase Analytics, por lo que recopila la siguiente información de su dispositivo:
- El país de su proveedor de Internet
- Hora de la sesión de trabajo de la aplicación

Todos estos datos se presentan como estadísticas, y no puede ser utilizado para obtener información personal de alguien

También esta aplicación utiliza Firebase Crashlytics, que recoge la siguiente información cuando la aplicación se bloquea:

- Modelo de tu dispositivo (IPhone X o IPad Pro (10.5 pulgadas) por ejemplo)

- Orientación del dispositivo
- Espacio libre en RAM y ROM
- Versión de IOS
- Hora del bloqueo
- Registro detallado del hilo donde ocurre el atasco

Toda esta información se utiliza para corregir errores y mejorar la calidad de esta aplicación.

Más información en [Firebase website](https://firebase.google.com)

## Licencia

Derechos de autor (c) 2019 XITRIX (Vinogradov Daniil)
Por la presente se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia
de este software y de los archivos de documentación asociados (el "Software"), para tratar 
con el software sin restricciones, incluidos, entre otros, los derechos de 
de utilizar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender
sublicenciar y/o vender copias del Software, y a permitir que las personas a las que se
el Software, con sujeción a las siguientes condiciones:
El aviso de copyright anterior y este aviso de permiso se incluirán en todas las
copias o partes sustanciales del Software.
EL SOFTWARE SE SUMINISTRA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O
IMPLÍCITA, INCLUIDAS, ENTRE OTRAS, LAS GARANTÍAS DE COMERCIABILIDAD
IDONEIDAD PARA UN FIN DETERMINADO Y NO INFRACCIÓN. EN NINGÚN CASO
AUTORES NI LOS TITULARES DE LOS DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN 
RESPONSABILIDAD, YA SEA CONTRACTUAL, EXTRACONTRACTUAL O DE OTRO TIPO, DERIVADA DE,
DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTRAS OPERACIONES CON EL
SOFTWARE.
