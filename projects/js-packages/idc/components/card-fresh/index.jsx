/**
 * External dependencies
 */
import React from 'react';
import PropTypes from 'prop-types';
import { Button, Dashicon } from '@wordpress/components';
import { useSelect } from '@wordpress/data';
import { createInterpolateElement } from '@wordpress/element';
import { __, sprintf } from '@wordpress/i18n';
import { Spinner } from '@automattic/jetpack-components';

/**
 * Internal dependencies
 */
import { STORE_ID } from '../../state/store';
import extractHostname from '../../tools/extract-hostname';

/**
 * The "start fresh" card.
 *
 * @param {object} props - The properties.
 * @returns {React.Component} The `ConnectScreen` component.
 */
const CardFresh = props => {
	const { isStartingFresh, startFreshCallback } = props;

	const wpcomHostName = extractHostname( props.wpcomHomeUrl );
	const currentHostName = extractHostname( props.currentUrl );

	const isActionInProgress = useSelect( select => select( STORE_ID ).getIsActionInProgress(), [] );

	const buttonLabel = __( 'Create a fresh connection', 'jetpack' );

	return (
		<div className="jp-idc__idc-screen__card-action-base">
			<div className="jp-idc__idc-screen__card-action-top">
				<h4>{ __( 'Treat each site as independent sites', 'jetpack' ) }</h4>

				<p>
					{ createInterpolateElement(
						sprintf(
							/* translators: %1$s: The current site domain name. %2$s: The original site domain name. */
							__(
								'<hostname>%1$s</hostname> settings, stats, and subscribers will start fresh. <hostname>%2$s</hostname> will keep its data as is.',
								'jetpack'
							),
							currentHostName,
							wpcomHostName
						),
						{
							hostname: <strong />,
						}
					) }
				</p>
			</div>

			<div className="jp-idc__idc-screen__card-action-bottom">
				<div className="jp-idc__idc-screen__card-action-sitename">{ wpcomHostName }</div>
				<Dashicon icon="minus" className="jp-idc__idc-screen__card-action-separator" />
				<div className="jp-idc__idc-screen__card-action-sitename">{ currentHostName }</div>

				<Button
					className="jp-idc__idc-screen__card-action-button"
					label={ buttonLabel }
					onClick={ startFreshCallback }
					disabled={ isActionInProgress }
				>
					{ isStartingFresh ? <Spinner /> : buttonLabel }
				</Button>
			</div>
		</div>
	);
};

CardFresh.propTypes = {
	/** The original site URL. */
	wpcomHomeUrl: PropTypes.string.isRequired,
	/** The current site URL. */
	currentUrl: PropTypes.string.isRequired,
	/** Whether starting fresh is in progress. */
	isStartingFresh: PropTypes.bool.isRequired,
	/** "Start Fresh" callback. */
	startFreshCallback: PropTypes.func.isRequired,
};

CardFresh.defaultProps = {
	isStartingFresh: false,
	startFreshCallback: () => {},
};

export default CardFresh;
