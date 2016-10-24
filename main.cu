#include <boost/type_traits/is_float.hpp>
#include <boost/mpl/vector.hpp>
#include <boost/mpl/accumulate.hpp>

/** MPL Iteration Algorithm Example
 */
namespace bmpl = boost::mpl;
typedef bmpl::vector<long, float, short, double, float, long, long double> types;
typedef bmpl::accumulate<
    types,
    bmpl::int_<0>,
    bmpl::if_< boost::is_float<bmpl::_2>, bmpl::next<bmpl::_1>, bmpl::_1 >
>::type number_of_floats;

BOOST_MPL_ASSERT_RELATION( number_of_floats::value, ==, 4 );


/** main
 */
int
main( int argc, char **argv )
{
    return 0;
}
