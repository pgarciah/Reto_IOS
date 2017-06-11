# Reto_IOS

 ------------------------------------------------------------------------------------------
COMENTARIOS GENERALES
 ------------------------------------------------------------------------------------------

 La aplicación se adapta a iPhone y iPad usando Autolayout. En el caso de iPhone, por ser la pantalla más pequeña se muestran dos vistas, una con el listado de elementos, y otra con el detalle independientemente de la orientación.
 
 En el caso de iPad, si el dispositivo está en landscape, se muestran a la vez las vistas de listado y detalle.
 
 Para listar los elementos se hace una de una celda customizada definida en otra clase.
 
 Los elementos se listan ordenados por fecha (de más reciente a más antigua) y pueden ser filtrados.
 
 En caso de haber obtenido alguna vez los elementos, la aplicación permite trabajar sin conexión, ya que mantiene una copia local de los elementos.
 
 El servicio para obtener los elementos se llama en otro hilo, de forma que el principal no queda bloqueado y puede mostrar el típico "Cargando...".
 
 Si se tiene conexión, se puede refrescar la información del RSS, haciendo scroll en la cabecera de la tabla (gesto habitual de refresh en listados).
 
 Las imágenes de cada item se obtienen de manera asíncrona. Además, una vez obtenidas se almacenan para que no tengan que volver a descargarse en caso de repintandos en la vista.

 Todo el código está comentado y ordenado por funcionalidades dentro de las clases.

 Como es habitual en IOS se han utilizado algunos patrones como Protocol, Delegate o Callback, que permiten facilitar la creación de código, haciendo obligatorio que una clase se encargue de realizar una determinada tarea.

 ------------------------------------------------------------------------------------------
 ESTRUCTURA DE LA APLICACIÓN
 ------------------------------------------------------------------------------------------
 
 La aplicación está estructurada de la siguente manera:

 - Views: Contiene todos los ViewController de la aplicación (en un subgrupo ViewController), así como el .storyboard y los diferentes .xib.
 
 En este caso solo tenemos un ViewController que maneja dos vistas (listado y detalle), ya que de esta manera podemos gestionar si se muestran ambas a la vez o por separado. Esto nos permite por ejemplo que en el caso de un dispositvo iPad en Landscape haya un diseño diferente al del resto de caso.

Igualmente, si se quisiera que el iPhone tuviese el mismo comportamiento el impacto del cambio en la aplicación sería mínimo gracias a esta implementación.

Por otro lado, dentro del Group Views, hay un subgrupo para las celdas personalizadas. En este caso hay una única celda que se utiliza para mostrar los diferentes items en la tabla.

- Beans: Aquí se almacenan todos los objetos que maneja la aplicación. En este caso hemos creado un bean para cada item del RSS, y otro para agrupar este bean con otros datos de interes en la respuesta del servicio.

- Services: Para aislar la implementación de los servicios de las vistas, se ha creado un objecto especial ServiceObject que contiene los métodos para consumir los diferentes servicios.

De esta forma, cualquier ViewController puede acceder a este objeto y hacer uso de sus métodos. Del mismo modo, se prodían incluir nuevas implementaciones de los servicios o incluir nuevos sin que los ViewControllers que ya los consuman se vean afectados por los cambios.

- Utils: En este grupo se almacenan todas las librerías externas de las que hace uso la Aplicación.

- Localizable.strings: Todos los texto de la aplicación se obtienen de su correspondiente fichero de strings, de forma que si se quieren añadir nuevos idiomas a la aplicación solo es necesario incluir un nuevo fichero, sin necesidad de modificar ninguna de las clases ya creadas en la aplicación.

 ------------------------------------------------------------------------------------------
 LIBRERIAS EXTERNAS
 ------------------------------------------------------------------------------------------
 Se hace uso de 4 librerías auxiliares:
 
 - UIImageViewAsyn -> Cargar imágenes en un hilo asíncrono. Esta librería permite obtener las imagenes en un hilo secundario, de forma que el hilo principal no se bloquee y el usuario puede ir usando la aplicación mientras las imágenes se cargan. Esta librería está integrada en muchas de la aplicaciones desarrolladas por CMC y cumple perfectamente las normas de seguridad de HPFortify.

 - MBProgressHUD -> Para mostrar/ocultar popUp de "cargando...". Permite crear popUp con el típico icono de loading y añadir un texto personalizado de forma sencilla. Dado que este elemento es muy usado en aplicaciones con servicios, incluyendo esta librería optimizamos código y agilizamos la creación de este tipo de elementos. Esta librería está integrada en muchas de la aplicaciones desarrolladas por CMC y cumple perfectamente las normas de seguridad de HPFortify.


 - XMLDictionary -> Para parsear código XML y transformarlo en estructuras de datos con las que poder trabajar. Dado que los servicios RSS devuelven respuestas en XML es indispensable tener un parseador de código que permita pasar la respuesta de XML a un objeto cuya estructura permita trabajar correctamente con él. En este caso hay dos opciones. Crear el parseador manualmente, o usar uno ya existente. Esta librería está integrada en muchas de la aplicaciones desarrolladas por CMC y cumple perfectamente las normas de seguridad de HPFortify.

 - Reachability -> Para comprobar si hay conexión de red y detectar cambios en la misma. En Aplicaciones que consumen servicios web es imprescindible comprobar si hay conexión de red, ya que de no ser así muchas de las funcionalidades no estarán operativas. En este caso, Apple recomienda la inclusión de esta librería para dicha tarea. Esta librería está integrada en muchas de la aplicaciones desarrolladas por CMC y cumple perfectamente las normas de seguridad de HPFortify.
